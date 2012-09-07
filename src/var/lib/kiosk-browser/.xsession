#!/bin/bash
exec 2> >(logger -t kiosk-browser)
set -x
if test -r /etc/default/kiosk-browser ; then
    source /etc/default/kiosk-browser
fi
xset s off
xset s noblank
while true; do
  rm -Rf ~/.config/chromium/* ~/.cache/chromium/*
  chromium-browser "${KIOSK_BROWSER_OPTIONS[@]}" --start-maximized --kiosk --app="${KIOSK_BROWSER_START_PAGE:=https://github.com/ImmobilienScout24/kiosk-browser}"
  sleep 5
done
