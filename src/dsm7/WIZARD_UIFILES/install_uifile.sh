#!/bin/sh

# Primary address via the default route. Falls back to the first global IPv4
# address, because a NAS on a network without a default gateway would
# otherwise be offered an empty field it cannot submit.
SYNO_IP=$(ip -o route get to 1.0.0.0 2>/dev/null | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
if [ -z "${SYNO_IP}" ]; then
    SYNO_IP=$(ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
fi

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Which SpotConnect program(s) do you want to install?",
        "items": [
            {
                "type": "singleselect",
                "desc": "Choose installation type:",
                "subitems": [
                    {
                        "key": "pkgwizard_binaries_both",
                        "desc": "(Default) spotupnp & spotraop",
                        "defaultValue": true
                    },
                    {
                        "key": "pkgwizard_binaries_spotupnp",
                        "desc": "Only spotupnp",
                        "defaultValue": false
                    },
                    {
                        "key": "pkgwizard_binaries_spotraop",
                        "desc": "Only spotraop",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "<strong style='color:red'>spotupnp</strong> = for UPnP/DLNA speakers and network receivers (Sonos, Bose SoundTouch, and older Denon/Yamaha/Onkyo-style streamers)"
            },
            {
                "desc": "<strong style='color:red'>spotraop</strong> = for AirPlay receivers (AirPort Express, AirPlay speakers, Apple TV)"
            },
            {
                "desc": "Not sure? Keep the default. Each speaker found will appear in your Spotify app as its own device, named with a trailing '+'."
            },
            {
                "desc": "Please refer to the <a target='_blank' href='https://github.com/eizedev/SpotConnect-Synology#readme'>documentation</a> in case of any problems or questions"
            }
        ]
    },
    {
        "step_title": "Connection properties",
        "items": [
            {
                "type": "textfield",
                "desc": "IP address SpotConnect will bind to (default: this NAS's primary IP)",
                "subitems": [
                    {
                        "key": "pkgwizard_ip",
                        "desc": "IP of your Synology device",
                        "defaultValue": "${SYNO_IP}",
                        "validator": {
                            "allowBlank": false
                        }
                    }
                ]
            },
            {
                "type": "textfield",
                "desc": "UPnP port for spotupnp (ignored if spotupnp is not installed). Must be above 49152. The default is chosen so it does not clash with AirConnect on the same NAS.",
                "subitems": [
                    {
                        "key": "pkgwizard_spotupnp_port",
                        "desc": "UPnP port for spotupnp",
                        "defaultValue": "49300",
                        "validator": {
                            "allowBlank": false
                        }
                    }
                ]
            }
        ]
    },
    {
        "step_title": "Keeping your speakers signed in",
        "items": [
            {
                "type": "multiselect",
                "desc": "After you play to a speaker once, SpotConnect receives a reusable token from Spotify and can store it. That is what keeps the speaker in your Spotify device list even when no Spotify app is running nearby - and what lets you start music from outside the house or from a home automation system. Without it, a speaker only appears while a Spotify app discovers it on your local network.",
                "subitems": [
                    {
                        "key": "pkgwizard_store_credentials",
                        "desc": "Keep my speakers signed in (recommended)",
                        "defaultValue": true
                    }
                ]
            },
            {
                "desc": "<strong>You never enter your Spotify password.</strong> This package deliberately offers no username/password option: passing them on a command line would make them readable by every local user via 'ps'. The stored token is issued by Spotify for this device and cannot be used to sign in to your account."
            },
            {
                "desc": "Tokens are written to a package-private folder (mode 0700) that only this package can read, and they are deleted when you uninstall the package."
            }
        ]
    }
];
EOF

exit 0
