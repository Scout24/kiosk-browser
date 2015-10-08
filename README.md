kiosk-browser
=============

[![Join the chat at https://gitter.im/ImmobilienScout24/kiosk-browser](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ImmobilienScout24/kiosk-browser?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Ubuntu/Debian/Raspbian package to set up a system as a kiosk browser. Release announcement and example photo can be found on my blog at http://blog.schlomo.schapiro.org/2012/09/dashboards-made-easy.html.

This package disables the regular GUI and installs a browser-only GUI. Keyboards and mice are disabled to prevent tampering.

The behavior can be customized in `/etc/default/kiosk-browser`:
*   Set `KIOSK_BROWSER_START_PAGE` to set the start page(s).
*   Set `KIOSK_BROWSER_PORTS` to autoconfigure these|this display ports (Use xrandr port names)
*   Set `KIOSK_BROWSER_XRANDR_EXTRA_OPTS` to rotate some displays or set other custom xrandr settings.
*   Set `KIOSK_BROWSER_WATCHDOG_TIMEOUT` to the amount of seconds after which the systems reboots if the screen did not change. Default is 3600. 
*   Set `KIOSK_BROWSER_WATCHDOG_CHECK_INTERVAL` to the check interval in seconds, default is 313.
*   Set `KIOSK_BROWSER_SHOW_SYSTEM_MONITOR=yes` to show [xosview](http://xosview.sourceforge.net/).
*   Set `KIOSK_BROWSER_VNC_VIEWER_DISPLAY=0` to enable a vncviewer in listening mode on port 5500.
*   Add custom initialization commands or pull the above configuration from somewhere else.

The package is licensed under the GNU Public License, see included
LICENSE.txt for full license text.

Building
========

1. Install `fakeroot`, `lintian` and `dpkg`.
1. Checkout this github repo and type `make`.
1. In `out` you should find the resulting .deb package file.

Installation
============

1. Install the .deb package you build just now from the `out` directory
1. Create `/etc/default/kiosk-browser` and set `KIOSK_BROWSER_START_PAGE`
1. Reboot the system

If you want to play with the settings without rebooting the system you can use this command to restart the kiosk browser:
    
    sudo kiosk-browser-control restart


Notes
=====

*   This package disables all inputs in the X server so that nobody can mess with your system or use it as an entry point into your network.


Customisation & Special Features
================================

Multi-Monitor Support
---------------------

kiosk-browser supports setting up multiple monitors with different browser windows. The implementation is somewhat tricky so that I would be happy to get some feedback on it.

Some of the above mentioned `KIOSK_BROWSER_*` variables can be [Bash Arrays](http://tldp.org/LDP/abs/html/arrays.html) and multi-monitor support is enabled by setting these variables to arrays. In each array the same position refers to the same display, for example:

    KIOSK_BROWSER_PORTS=(HDMI1 HDMI2)
    KIOSK_BROWSER_XRANDR_EXTRA_OPTS=("" "--rotate left")
    KIOSK_BROWSER_START_PAGE=( 
        http://blog.schlomo.schapiro.org
        http://go.schapiro.org/schlomo
    )

Note the empty (`""`) array value which means no extra xrandr options for HDMI1. For single monitor operations you can still use these variables to configure the display, e.g.:

    KIOSK_BROWSER_PORTS=VGA
    KIOSK_BROWSER_XRANDR_EXTRA_OPTS="--rotate left"
    KIOSK_BROWSER_START_PAGE=http://blog.schlomo.schapiro.org

If you don't know if the VGA port is called VGA or VGA1 you can specify a substring and the scripts will use the first connected port that matches. Here we basically use the fact that a Bash String is exactly the same as a Bash Array with a single value in it.


Different Browsers
------------------

The default browser is [Chromium](http://www.chromium.org/). kiosk-browser also supports [Epiphany](https://wiki.gnome.org/Apps/Web) and [Uzbl](http://www.uzbl.org/) as browsers. To use a different browser set the `KIOSK_BROWSER_PROGRAM` variable to either `epiphany` or `uzbl`. Since September 2014 epiphany [has been greatly improved on Raspberry Pi](http://www.raspberrypi.org/web-browser-released/) so that it is worth to try it out.

Virtual Projector
-----------------

If you use the kiosk-browser package to drive a large-screen team dashboard then you can also use it as a projector. Enable VNC support with the `KIOSK_BROWSER_VNC_VIEWER_DISPLAY` and "beam" your desktop to the screen with a VNC reverse connection (VNC server connects to the VNC client).

**Linux Clients**

Install `x11vnc` and use `x11vnc -connect <HOSTNAME>` to send your desktop. [x11vnc](http://www.karlrunge.com/x11vnc/) has many options to fine-tune the VNC session, including scaling your desktop to fit the native resolution of the kiosk-browser screen.

**Windows Clients**

Install [TightVNC Server](http://www.tightvnc.com/download.php) and use the "Attach Listening Viewer" menu to connect.

**Mac Clients**

Install [Vine Server (osxvnc)](http://downloads.testplant.com/downloads/Vine/VineServer4.01.dmg) and add a "Reverse Connection"


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

Show more than one page
-----------------------

Sometimes a dashboard should cycle between several views. I think that this should be done on the server side, not the client side. For example, create on your web server a file named `urls.js` like this with the URLs in it:

        var urls = [ 
                "http://www.schapiro.org/schlomo/publications",
                "http://www.schapiro.org/schlomo/videos"
                ];

And next to it another file with the HTML code, named `dashboard.html`:

        <!DOCTYPE html>
        <html>
        <head>
        <script type="text/javascript" src="urls.js"></script>
        <script type="text/javascript">
        
        function start() {
                setInterval(function(){cycle()},60000);
                cycle();
        }
        
        var counter = 0;
        function cycle() {
                var iframe = document.getElementById("iframe");
                iframe.src=urls[counter++];
                if (counter >= urls.length) {
                        counter = 0;
                }
        }
        
        </script>
        <style type="text/css">
        body,iframe {
                padding: 0px;
                margin: 0px;
        }
        #wrap { position:fixed; left:0; width:100%; top:0; height:100%; }
        #iframe { display: block; width:100%; height:100%; }
        </style>
        <title>Dashboard switcher by Schlomo Schapiro</title>
        </head>
        <body onload="start()">
        <div id="wrap"><iframe id="iframe" src=""/></div>
        </body>
        </html>

Finally, adjust `KIOSK_BROWSER_START_PAGE` in `/etc/default/kiosk-browser` to point to this `dashboard.html` and you are done.

Hacking
=======

The kiosk-browser user session creates a temporary Home Directory under `/tmp`. To access the running kiosk-browser session use `kiosk-browser-control interactive`. In the shell you can use `cd` to go to the session Home Directory.
