#!/bin/bash
exec 2> >(logger -t kiosk-browser)
set -x
if test -r /etc/default/kiosk-browser ; then
    source /etc/default/kiosk-browser
fi

# windows manager helps with fullscreen
metacity &

# disable screen blanking
xset -dpms
xset s off
xset s noblank

while true; do
  # wipe state data
  rm -Rf ~/.config/chromium/* ~/.cache/* ~/.pki/*
  chromium-browser "${KIOSK_BROWSER_OPTIONS[@]}" --no-first-run --start-maximized --kiosk "${KIOSK_BROWSER_START_PAGE:=https://github.com/ImmobilienScout24/kiosk-browser}"
  sleep 5
done
