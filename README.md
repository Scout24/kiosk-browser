kiosk-browser
=============

Ubuntu package to set up a system as a kiosk browser.

This package disables the regular GUI and installs a browser-only GUI.

The behaviour can be customized in <code>/etc/default/kiosk-browser</code>:
* Set KIOSK_BROWSER_START_PAGE change start page.
* Add custom initialization commands. As an example I use
```
xrandr --output VGA1 --auto --output LVDS1 --off
sleep 5
```
on a system which configures the displays properly.

