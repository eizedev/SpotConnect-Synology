#!/bin/sh

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Before you uninstall",
        "items": [
            {
                "desc": "Uninstalling removes this package's folder, including <strong>spotconnect.conf</strong>, the log, any custom config-upnp.xml / config-raop.xml, and the stored Spotify tokens. Nothing is kept outside the package folder, so there is nothing left behind to clean up."
            },
            {
                "desc": "Your speakers themselves are not changed in any way - they simply stop appearing as Spotify Connect devices."
            },
            {
                "desc": "If you reinstall later, play to each speaker once from a Spotify app to have it signed in again."
            }
        ]
    }
];
EOF

exit 0
