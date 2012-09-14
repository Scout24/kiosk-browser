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

The package is licensed under the GNU Public License, see included
LICENSE.txt for full license text.

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

If you want to play with the settings without rebooting the system you can use this command to restart the kiosk browser:
    
    sudo service nodm stop ; sudo pkill -u kiosk-browser ; sleep 5 ; sudo service nodm start

The reason for this hack is that nodm does not kill all sub-processes on shutdown.
    
Customisation
=============

Chromium Preferences
--------------------

The chromium profile is wiped on each start. To set chromium preferences you can use the master_preferences mechanism and create
a `/usr/lib/chromium-browser/master_preferences` file with preferences. For example I use

    {
        "profile" : {
            "default_zoom_level" : 2.22390108574155
        }
    }

to set the zoom level to 150%. This allows us to have dashboards that look fine both on my desktop and on the kiosk browser.
