#!/bin/sh

# Only worth asking if there is actually something stored to forget.
CRED_COUNT=0
if [ -d "${SYNOPKG_PKGDEST}/credentials" ]; then
    CRED_COUNT=$(find "${SYNOPKG_PKGDEST}/credentials" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
fi

if [ "${CRED_COUNT}" -eq 0 ]; then
    echo '[]' >"$SYNOPKG_TEMP_LOGFILE"
    exit 0
fi

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Spotify sign-ins",
        "items": [
            {
                "desc": "This package currently holds stored sign-ins for <strong>${CRED_COUNT}</strong> speaker(s). They are kept across this update, so your speakers stay in your Spotify device list. Normally there is nothing to do here - just continue."
            },
            {
                "type": "multiselect",
                "desc": "Clear them only if you switched to a different Spotify account, or if a speaker stopped responding and you want it to sign in fresh:",
                "subitems": [
                    {
                        "key": "pkgwizard_forget_credentials",
                        "desc": "Forget stored Spotify sign-ins",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "After clearing, each speaker returns to local discovery until you play to it once from a Spotify app - at which point a fresh sign-in is stored automatically. Nothing else is affected: your settings and logs are kept either way."
            }
        ]
    }
];
EOF

exit 0
