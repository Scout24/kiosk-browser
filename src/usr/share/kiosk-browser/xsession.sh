#!/bin/bash
exec &> >(exec logger -t "kiosk-browser[$$]" )

# sanitize environment
export LANG=en_US LANGUAGE=en_US LC_ALL=en_US.UTF-8
unset ${!XDG_*}
set -x

KILL_ON_EXIT=
HOME=$( mktemp -d /tmp/kiosk-browser.HOME.XXXXXXXXXXXXX )
function exittrap {
    procs=( $KILL_ON_EXIT $(jobs -p))
    kill -TERM ${procs[@]}
    (
        # wait in background for all procs to be gone before removing the old home directory
        # reason is that nodm KILLs the session 2 seconds after TERMinating it
        sleep 5 &
        wait $!
        kill -KILL $KILL_ON_EXIT ${procs[@]} &>/dev/null
        rm -Rf $HOME
        pstree -paul $USER
        pkill -KILL -e -u $USER # harakiri
    ) </dev/null &
}
trap exittrap TERM EXIT # kill subprocesses on exit

# dump what we got so far
declare -p
pstree -paul $USER

# Wait 30 seconds for network by checking for default route
(( end_time=SECONDS+30 ))
until (( SECONDS > end_time)) || [[ "$(ip route)" == *default* ]] ; do
    sleep 2 &
    wait $!
done

# show debug info for 60 seconds as overlay
{
    echo "Welcome to the Kiosk Browser (http://github.com/ImmobilienScout24/kiosk-browser)"
    echo
    echo "This is $(uname -n)"
    ip a
    ip route
    cat /etc/resolv.conf
    perl -e '$/ = undef; $d=<>; $d =~ m/.*(lease {.*?})$/s ; print $1' $(ps ax | grep dhclient | sed -ne "s/.* \(\/[^ ]\+\.lease[s]\?\).*/\1/p") <<<""
    echo
    echo "This message will self-destruct in 60 seconds"
} | osd_cat --pos bottom --align left --colour green --outline 2 --font 10x20 --lines 50 --delay 60 &

disown -a # forget about running osd_cat, it will terminate itself anyway

# window manager helps with fullscreen, window manager must support XINERAMA for multi-screen setups
openbox --debug --config-file /usr/share/kiosk-browser/openbox-rc.xml &


# cache xrandr configuration
XRANDR_OUTPUT="$(xrandr)"
function xrandr_find_port {
    # find connected port matching pattern
    sed -n -e "/$1.* connect/s/^\([^ ]\+\).*/\1/p" <<<"$XRANDR_OUTPUT"
}

if test -r /etc/default/kiosk-browser ; then
    source /etc/default/kiosk-browser
fi


if [[ ! "$KIOSK_BROWSER_PORTS" ]] ; then
    # set . as a built-in default to use the first connected port that xrandr reports
    KIOSK_BROWSER_PORTS=.
fi

if [[ ! "$KIOSK_BROWSER_START_PAGE" ]] ; then
    # point to our github page as built-in default
    KIOSK_BROWSER_START_PAGE=https://github.com/ImmobilienScout24/kiosk-browser
fi

KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL="${KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL:-313}"
if [[ ! "$KIOSK_BROWSER_WATCHDOG_TIMEOUT" ]] ; then
    # default stale screen watchdog is 1h
    KIOSK_BROWSER_WATCHDOG_TIMEOUT=3600
fi

if [[ ! "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" ]] ; then
    # disable VNC viewer by default
    KIOSK_BROWSER_VNC_VIEWER_DISPLAY=-1
fi

# configure displays
xrandr $(
    xrandr_position=
    for (( c=0 ; c<${#KIOSK_BROWSER_PORTS[@]} ; c++ )) ; do
        port=$(xrandr_find_port "${KIOSK_BROWSER_PORTS[c]}")
        if [[ "$port" ]] ; then
            #                                                                        / we use xrandr_position as indicator of first port
            echo "--output $port ${KIOSK_BROWSER_XRANDR_EXTRA_OPTS[c]} $( [[ -z "$xrandr_position" ]] && echo --primary ) $xrandr_position --auto"
            xrandr_position="--right-of $port"
        else
            : skipping configuration of "${KIOSK_BROWSER_PORTS[c]}" because it is not connected
        fi
    done
)

# wait a moment for displays to settle
sleep 5 &
wait $!

# xrandr configuration changed, update cache
XRANDR_OUTPUT="$(xrandr)"

# disable screen blanking
xset -dpms
xset s off
xset s noblank

# start watchdog, reboot system if screen stops to change
if (( KIOSK_BROWSER_WATCHDOG_TIMEOUT > 0 )) ; then
    (
	WATCHDOG_PID=$BASHPID
	exec &> >(exec logger -t "kiosk-browser[$$]-watchdog[$WATCHDOG_PID]" )
	: "Starting watchdog. Timeout is $KIOSK_BROWSER_WATCHDOG_TIMEOUT seconds, checking every $KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL seconds"
        trap 'kill -TERM $(jobs -p)' TERM

        LASTHASH=""
        LASTCHANGED="$SECONDS"
        while sleep $KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL & wait $! ; do 
            HASH=$(nice import -display :0 -window root -monochrome jpg:- | nice identify -format '%#' -)
            #declare -p HASH LASTHASH LASTCHANGED SECONDS
            if [[ "$HASH" = "$LASTHASH" ]] ; then 
                if (( SECONDS > LASTCHANGED + KIOSK_BROWSER_WATCHDOG_TIMEOUT )) ; then
                sudo /sbin/reboot
                break
                fi
            else
                LASTHASH="$HASH"
                LASTCHANGED="$SECONDS"
            fi
        done
    ) </dev/null 1>&2 &
fi

if [[ "$KIOSK_BROWSER_SHOW_SYSTEM_MONITOR" ]] ; then
    xosview &
fi

# start vnc viewer if requested
if [[ "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" ]] && (( KIOSK_BROWSER_VNC_VIEWER_DISPLAY >= 0 )) ; then
    vncviewer -fullscreen -viewonly -listen "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" &
fi

# remember system jobs
KILL_ON_EXIT=$(jobs -p)
# the wait below should wait only for the browsers and not hang on the system jobs
disown -a

# Ubuntu has chromium-browser and Debian wheezy has chromium
CHROME=$(type -p chromium-browser 2>/dev/null)
if [[ -z "$CHROME" ]] ; then
    CHROME=$(type -p chromium 2>/dev/null)
fi


UZBL_CONFIG="set show_status=0
set geometry=maximized"

while sleep 5 & wait $!; do
    # exit if no display given, use xwininfo to test for running X server
    xwininfo -root &>/dev/null || exit 99

    # if KIOSK_BROWSER_PORTS is set, assume that it specifies multiple screens connected.
    for (( c=0 ; c<${#KIOSK_BROWSER_PORTS[@]} ; c++ )) ; do
        port=$(xrandr_find_port "${KIOSK_BROWSER_PORTS[c]}")
        [[ -z "$port" ]] && continue # skip for all invalid ports (that are not a number)
        port_x=$(sed -ne "/$port/s#[^+].*+\([0-9]\+\)+.*#\1#p" <<<"$XRANDR_OUTPUT")

        BROWSER_PROFILE_DIR=~/profile-$c
        URL="${KIOSK_BROWSER_START_PAGE[c]:-$KIOSK_BROWSER_START_PAGE}"

        # start with empty profile dir
        [[ -d $BROWSER_PROFILE_DIR ]] && rm -Rf $BROWSER_PROFILE_DIR
        mkdir -p $BROWSER_PROFILE_DIR

        if [[ "$KIOSK_BROWSER_PROGRAM" == "epiphany" ]] && type -p epiphany-browser &>/dev/null ; then
            epiphany-browser --class epiphany-$c --profile $BROWSER_PROFILE_DIR "$URL" &
            PID=$!
            sleep 10 &
            wait $!
            # Use PID to distinguish browsers
            xdotool search --class epiphany-$c windowmove --sync $port_x 0 key F11
        elif [[ "$KIOSK_BROWSER_PROGRAM" == "uzbl" ]] && type -p uzbl &>/dev/null ; then
            uzbl -n uzbl-$c -c - "$URL" <<<"$UZBL_CONFIG" &
            sleep 5 &
            wait $!
            xdotool search --class uzbl-$c windowmove --sync $port_x 0
        else
            $CHROME --user-data-dir=$BROWSER_PROFILE_DIR "${KIOSK_BROWSER_OPTIONS[@]}" --use-fake-ui-for-media-stream --disable-translate --no-first-run --start-fullscreen --app="$URL" &
            PID=$!

            # move new window to the current screen. We identify the window by the --user-data-dir option which appears in the window class name :-)

            starttime=$SECONDS
            while ! xdotool search --onlyvisible --pid $PID --name any windowmove --sync $port_x 0 ; do
                if (( SECONDS-starttime > 30 )) ; then
                    killall -TERM ${CHROME##*/} # if we can't find a chrome window then we kill them all and try again, killall needs only basename
                    sleep 2 &
                    wait $!
                    killall -KILL ${CHROME##*/}
                    kill -KILL $(jobs -p) # kill all background jobs (= browsers) to restart outer while loop
                    break 2 # abort the for loop
                fi
                sleep 2 &
                wait $!
            done
        fi
    done

    xdotool search xosview windowactivate # make sure xosview is visible

    wait # for the browsers to finish
done

# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4
