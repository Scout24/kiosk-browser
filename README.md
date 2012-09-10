kiosk-browser
=============

Ubuntu package to set up a system as a kiosk browser.

This package disables the regular GUI and installs a browser-only GUI.

The behaviour can be customized in `/etc/default/kiosk-browser`:
*   Set `KIOSK_BROWSER_START_PAGE` change start page.

*   Add custom initialization commands. As an example I use
    > xrandr --output VGA1 --auto --output LVDS1 --off  
    > sleep 5

    on a system which configures the displays properly.

Building
========

1. Install `fakeroot` and `dpkg`.
1. Checkout this github repo and type `make`.
1. In `out` you should find the resulting .deb package file.

Installation
============

1. Install the .deb package from [out](kiosk-browser/tree/master/out/)
1. Create `/etc/default/kiosk-browser` and set `KIOSK_BROWSER_START_PAGE`
1. Reboot the system
