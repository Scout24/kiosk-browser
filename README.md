kiosk-browser
=============

Ubuntu package to set up a system as a kiosk browser. Release announcement and example foto] can be found on my blog at http://blog.schlomo.schapiro.org/2012/09/dashboards-made-easy.html.

This package disables the regular GUI and installs a browser-only GUI.

The behaviour can be customized in `/etc/default/kiosk-browser`:
*   Set `KIOSK_BROWSER_START_PAGE` to set the start page(s).
*   Set `KIOSK_BROWSER_PORTS` to autoconfigure these|this display ports (Use xrandr port names)
*   Set `KIOSK_BROWSER_XRANDR_EXTRA_OPTS` to rotate some displays or have other custom xrandr settings.
*   Add custom initialization commands or pull the above configuration from somewhere else.

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

Notes
=====

*   This package disables all inputs in the X server so that nobody can mess with your system or use it as an entry point into your network.
    
Customisation
=============

Multi-Monitor Support
------------

kiosk-browser supports setting up multiple monitors with different browser windows. The implementation is somewhat tricky so that I would be happy to get some feedback on it.

The above mentioned `KIOSK_BROWSER_*` variables can be all [Bash Arrays](http://tldp.org/LDP/abs/html/arrays.html) and multi-monitor support is enabled by setting these variables to arrays. In each array the same position refers to the same display, for example:

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
