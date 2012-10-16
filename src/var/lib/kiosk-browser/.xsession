#!/bin/bash
exec 2> >(logger -t kiosk-browser)

# windows manager helps with fullscreen
metacity &

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
	KIOKS_BROWSER_PORTS=.
fi

if [[ ! "$KIOSK_BROWSER_START_PAGE" ]] ; then
	# point to our github page as built-in default
	KIOSK_BROWSER_START_PAGE=https://github.com/ImmobilienScout24/kiosk-browser
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

#forget about running jobs
disown -a

while true; do
	# exit if no display given, use xwininfo to test for running X server
	xwininfo -root &>/dev/null || exit 0
	# wipe state data
	rm -Rf ~/.config/chromium/* ~/.cache/* ~/.pki/*
	# if KIOSK_BROWSER_PORTS is set, assume that it specifies multiple screens connected.
	for (( c=0 ; c<${#KIOSK_BROWSER_PORTS[@]} ; c++ )) ; do
		chromium-browser --user-data-dir=$HOME/.config/chromium/$c "${KIOSK_BROWSER_OPTIONS[@]}" --no-first-run --start-maximized --kiosk "${KIOSK_BROWSER_START_PAGE[c]:-$KIOSK_BROWSER_START_PAGE}" &
		sleep 1
		# move new window to the current screen. We identify the window by the --user-data-dir option which appears in the window class name :-)
		port=$(xrandr_find_port "${KIOSK_BROWSER_PORTS[c]}")
		port_x=$(sed -ne "/$port/s#[^+].*+\([0-9]\+\)+.*#\1#p" <<<"$XRANDR_OUTPUT")
		xdotool search --classname chromium/$c windowmove --sync $port_x 0
	done

	wait # for the browsers to finish
	sleep 5
done
