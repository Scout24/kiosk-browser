#!/bin/bash
exec 2> >(logger -t kiosk-browser)

# windows manager helps with fullscreen
metacity &

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
} | osd_cat --pos bottom --align left --colour green --font 10x20 --lines 50 --delay 60

# cache xrandr configuration
XRANDR_OUTPUT="$(xrandr)"
function xrandr_find_port {
    # find connected port matching pattern
    read port junk < <(grep connect <<<"$XRANDR_OUTPUT" | grep -i "$1") ; echo $port
}

function xrandr_find_other_ports {
    # find ports NOT matching pattern
    grep connect <<<"$XRANDR_OUTPUT" | cut -f 1 -d " " | grep -v $(xrandr_find_port "$1")
}

set -x
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

if [[ ! "$KIOSK_BROWSER_WATCHDOG_TIMEOUT" ]] ; then
    # default stale screen watchdog is 1h
    KIOSK_BROWSER_WATCHDOG_TIMEOUT=3600
fi

if [[ ! "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" ]] ; then
    # disable VNC viewer by default
    KIOSK_BROWSER_VNC_VIEWER_DISPLAY=0
fi

# configure displays
xrandr $(
	xrandr_position=
	for (( c=0 ; c<${#KIOSK_BROWSER_PORTS[@]} ; c++ )) ; do
		port=$(xrandr_find_port "${KIOSK_BROWSER_PORTS[c]}")
		echo "--output $port ${KIOSK_BROWSER_XRANDR_EXTRA_OPTS[c]} $xrandr_position --auto"
		xrandr_position="--right-of $port"
	done
	)
sleep 3

# xrandr configuration changed, update cache
XRANDR_OUTPUT="$(xrandr)"

# disable screen blanking
xset -dpms
xset s off
xset s noblank

KILL_ON_EXIT=()
function exittrap {
    kill ${KILL_ON_EXIT[@]}
}

trap exittrap 0 # kill subprocesses on exit

# start watchdog, reboot system if screen stops to change
if (( KIOSK_BROWSER_WATCHDOG_TIMEOUT > 0 )) ; then
    LASTHASH=""
    LASTCHANGED="$SECONDS"
    while sleep "${KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL:-313}" ; do 
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
    done </dev/null 1>&2 &
    KILL_ON_EXIT=( ${KILL_ON_EXIT[@]} $! ) # kill watchdog on exit
fi

if [[ "$KIOSK_BROWSER_SHOW_SYSTEM_MONITOR" ]] ; then
    xosview &
    KILL_ON_EXIT=( ${KILL_ON_EXIT[@]} $! ) # kill system viewer on exit
fi

# start vnc viewer if requested
if [[ "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" ]] && (( KIOSK_BROWSER_VNC_VIEWER_DISPLAY >= 0 )) ; then
    vncviewer -fullscreen -viewonly -listen "$KIOSK_BROWSER_VNC_VIEWER_DISPLAY" &
    KILL_ON_EXIT=( ${KILL_ON_EXIT[@]} $! ) # kill vncviewer on exit
fi

#forget about running jobs, the relevant ones are in KILL_ON_EXIT
disown -a

# Ubuntu has chromium-browser and Debian wheezy has chromium
CHROME=$(type -p chromium-browser 2>/dev/null)
if [[ -z "$CHROME" ]] ; then
    CHROME=$(type -p chromium 2>/dev/null)
fi

while true; do
	# exit if no display given, use xwininfo to test for running X server
	xwininfo -root &>/dev/null || exit 0
	# wipe state data
	rm -Rf ~/.config/chromium/* ~/.cache/* ~/.pki/*
	# if KIOSK_BROWSER_PORTS is set, assume that it specifies multiple screens connected.
	for (( c=0 ; c<${#KIOSK_BROWSER_PORTS[@]} ; c++ )) ; do
		$CHROME --user-data-dir=$HOME/.config/chromium/$c "${KIOSK_BROWSER_OPTIONS[@]}" --disable-translate --no-first-run "${KIOSK_BROWSER_START_PAGE[c]:-$KIOSK_BROWSER_START_PAGE}" &
		sleep 5
		# move new window to the current screen. We identify the window by the --user-data-dir option which appears in the window class name :-)
		port=$(xrandr_find_port "${KIOSK_BROWSER_PORTS[c]}")
		port_x=$(sed -ne "/$port/s#[^+].*+\([0-9]\+\)+.*#\1#p" <<<"$XRANDR_OUTPUT")
		xdotool search --classname chromium/$c windowmove --sync $port_x 0 key F11
	done

	wait # for the browsers to finish
	sleep 15
done
