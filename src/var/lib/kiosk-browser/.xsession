#!/bin/bash
exec 2> >(logger -t kiosk-browser)
set -x
if test -r /etc/default/kiosk-browser ; then
    source /etc/default/kiosk-browser
fi

# disable screen blanking
xset -dpms
xset s off
xset s noblank

# disable X cursor, found in http://ask.slashdot.org/comments.pl?sid=55567&cid=5415169
emptycursor="#define nn1_width 16
#define nn1_height 16
static unsigned char nn1_bits[] = {
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"
xsetroot -cursor <( echo "$emptycursor" ) <( echo "$emptycursor" )

while true; do
  rm -Rf ~/.config/chromium/* ~/.cache/chromium/*
  chromium-browser "${KIOSK_BROWSER_OPTIONS[@]}" --start-maximized --kiosk "${KIOSK_BROWSER_START_PAGE:=https://github.com/ImmobilienScout24/kiosk-browser}"
  sleep 5
done
