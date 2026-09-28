#!/bin/sh
# Simulate what an update does to an existing installation's settings.
#
# Carried over from AirConnect-Synology, whose doc/CONVENTIONS.md ("Updates")
# holds the rule this checks: an update works out what an installation is
# doing from the device, keeps what it cannot determine, and refuses rather
# than continue with settings it could not carry over. This runs preupgrade,
# the upgrade wizard and postupgrade against prepared installations and
# checks the result, so that is tested rather than assumed.
#
# Unlike AirConnect's settings, the Spotify sign-ins live in the package
# directory, which an update replaces. So the package directory is emptied
# between preupgrade and postupgrade, as DSM does - otherwise anything
# preupgrade failed to save would still look carried over.
#
# Usage: tests/upgrade_state.sh
# Exit status: 0 if every scenario behaves as expected.

set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TREE="$REPO_ROOT/src/dsm7"
FAIL=0
RUN=0

fail() {
    echo "  FAIL: $1"
    FAIL=1
}

pass() {
    echo "  ok: $1"
}

# expect <description> <command...>: one check, passing if the command does.
expect() {
    RUN=$((RUN + 1))
    desc=$1
    shift
    if "$@"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

# Every key a fresh install writes, read from postinst itself, so a key
# added there without a backfill in postupgrade shows up here.
CONFIG_KEYS=$(sed -n '/<<EOF/,/^EOF/s/^\([A-Z_][A-Z0-9_]*\)=.*/\1/p' "$TREE/scripts/postinst")

# A throwaway copy of an installed package, as DSM would have it:
# $WORK/pkg   is SYNOPKG_PKGDEST (the installed files, incl. config and sign-ins)
# $WORK/tmp   is SYNOPKG_TEMP_UPGRADE_FOLDER (preupgrade's backup)
setup() {
    WORK=$(mktemp -d)
    mkdir -p "$WORK/pkg/log" "$WORK/tmp"
    export SYNOPKG_PKGDEST="$WORK/pkg"
    export SYNOPKG_TEMP_UPGRADE_FOLDER="$WORK/tmp"
    export SYNOPKG_PKGNAME="SpotConnect"
    export SYNOPKG_TEMP_LOGFILE="$WORK/dsm-message.log"
    : >"$SYNOPKG_TEMP_LOGFILE"
    unset pkgwizard_forget_credentials || true
    CONFIG="$SYNOPKG_PKGDEST/spotconnect.conf"
}

teardown() {
    chmod -R u+w "$WORK" 2>/dev/null || true
    rm -rf "$WORK"
}

# A config as the current postinst writes it, with one value changed from
# the default so it is visible whether the user's values survive.
config_current() {
    cat >"$CONFIG" <<'CONF'
SYNO_IP="192.168.1.2"

SPOTUPNP_ENABLED=1
SPOTUPNP_PORT="49300"
SPOTUPNP_PORTRANGE="49301:128"
SPOTUPNP_CODEC="flc"
SPOTUPNP_CONTENTLENGTH_MODE=0
SPOTUPNP_RATE=320
SPOTUPNP_NAME_FORMAT="%s+"
SPOTUPNP_LOGLEVEL="all=info"

SPOTRAOP_ENABLED=1
SPOTRAOP_PORTRANGE="49430:128"
SPOTRAOP_CODEC="alac"
SPOTRAOP_RATE=320
SPOTRAOP_NAME_FORMAT="%s+"
SPOTRAOP_LOGLEVEL="all=info"

SPOTCONNECT_CREDENTIALS_ENABLED=1
CONF
}

# A config from before most of today's keys existed.
config_old() {
    cat >"$CONFIG" <<'CONF'
SYNO_IP="192.168.1.2"
SPOTUPNP_ENABLED=1
SPOTUPNP_PORT="49400"
CONF
}

signins_stored() {
    mkdir -p "$SYNOPKG_PKGDEST/credentials"
    chmod 700 "$SYNOPKG_PKGDEST/credentials"
    echo '{}' >"$SYNOPKG_PKGDEST/credentials/speaker-a.json"
    echo '{}' >"$SYNOPKG_PKGDEST/credentials/speaker-b.json"
}

custom_xml() {
    echo '<spotupnp><device><name>Kitchen</name></device></spotupnp>' >"$SYNOPKG_PKGDEST/config-upnp.xml"
}

# What the wizard would preselect: "true", "false", or "none" when it
# offers no checkbox.
wizard_answer() {
    sh "$TREE/WIZARD_UIFILES/upgrade_uifile.sh" >/dev/null 2>&1
    answer=$(sed -n 's/.*"defaultValue": \([a-z]*\).*/\1/p' "$SYNOPKG_TEMP_LOGFILE" | tail -n 1)
    : >"$SYNOPKG_TEMP_LOGFILE"
    echo "${answer:-none}"
}

# preupgrade, DSM swapping in the new package's files, postupgrade.
run_upgrade() {
    sh "$TREE/scripts/preupgrade" || return $?
    rm -rf "$SYNOPKG_PKGDEST"
    mkdir -p "$SYNOPKG_PKGDEST/log"
    sh "$TREE/scripts/postupgrade" || return $?
}

value_of() {
    sed -n "s/^$1=//p" "$CONFIG" | tail -n 1
}

mode_of() {
    # GNU stat first (CI), BSD stat as a fallback (macOS).
    stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

signins_count() {
    find "$SYNOPKG_PKGDEST/credentials" -name '*.json' 2>/dev/null | wc -l | tr -d ' '
}

echo "== src/dsm7 =="

# The normal case: sign-ins stored, the wizard left alone. DSM submits
# nothing or "false" for an untouched checkbox; both must keep everything.
for answer in none false; do
    setup
    config_current
    signins_stored
    custom_xml
    cp "$CONFIG" "$WORK/config-before"
    expect "sign-ins stored: wizard offers to forget them, unticked" [ "$(wizard_answer)" = "false" ]
    [ "$answer" = "none" ] || export pkgwizard_forget_credentials="$answer"
    run_upgrade
    expect "wizard answer $answer: config carried over unchanged" cmp -s "$CONFIG" "$WORK/config-before"
    expect "wizard answer $answer: sign-ins carried over" [ "$(signins_count)" = "2" ]
    expect "wizard answer $answer: sign-ins directory stays 0700" [ "$(mode_of "$SYNOPKG_PKGDEST/credentials")" = "700" ]
    expect "wizard answer $answer: edited config-upnp.xml carried over" grep -q Kitchen "$SYNOPKG_PKGDEST/config-upnp.xml"
    teardown
done

# The user asks to forget the sign-ins: they go, nothing else does.
setup
config_current
signins_stored
cp "$CONFIG" "$WORK/config-before"
export pkgwizard_forget_credentials="true"
run_upgrade
expect "user forgets sign-ins: they are gone" [ "$(signins_count)" = "0" ]
expect "user forgets sign-ins: directory kept at 0700" [ "$(mode_of "$SYNOPKG_PKGDEST/credentials")" = "700" ]
expect "user forgets sign-ins: DSM says how to get them back" grep -q "from a Spotify app" "$SYNOPKG_TEMP_LOGFILE"
expect "user forgets sign-ins: config untouched" cmp -s "$CONFIG" "$WORK/config-before"
teardown

# Nothing stored: nothing to offer, and the directory is there for the
# first sign-in with the right mode.
setup
config_current
expect "no sign-ins: wizard offers no checkbox" [ "$(wizard_answer)" = "none" ]
run_upgrade
expect "no sign-ins: directory created at 0700" [ "$(mode_of "$SYNOPKG_PKGDEST/credentials" 2>/dev/null)" = "700" ]
teardown

# A config older than today's keys: every key postinst writes is present
# afterwards, and what the user had is kept.
setup
config_old
run_upgrade
missing=""
for key in $CONFIG_KEYS; do
    grep -q "^${key}=" "$CONFIG" || missing="$missing $key"
done
expect "old config: every key postinst writes is backfilled${missing:+ (missing:$missing)}" [ -z "$missing" ]
expect "old config: existing port kept" [ "$(value_of SPOTUPNP_PORT)" = '"49400"' ]
expect "old config: existing enabled flag kept" [ "$(value_of SPOTUPNP_ENABLED)" = "1" ]
expect "old config: no key written twice" [ "$(grep -c "^SPOTUPNP_PORT=" "$CONFIG")" = "1" ]
teardown

# SYNO_IP missing: it is detected again rather than left out.
setup
config_current
sed '/^SYNO_IP=/d' "$CONFIG" >"$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
run_upgrade
expect "config without SYNO_IP: line added" grep -q "^SYNO_IP=" "$CONFIG"
teardown

# No config at all: the settings cannot be carried over, so the update
# must stop rather than continue with invented ones.
setup
signins_stored
RUN=$((RUN + 1))
if sh "$TREE/scripts/preupgrade" 2>/dev/null; then
    fail "update continued although there is no config to carry over"
elif grep -q "uninstall" "$SYNOPKG_TEMP_LOGFILE"; then
    pass "no config: update refused, and DSM is told to uninstall and reinstall"
else
    fail "no config: update refused, but the message doesn't say what to do"
fi
teardown

# The config is there but cannot be saved for the update. Needs a user
# that file permissions apply to, so it is skipped when run as root.
if [ "$(id -u)" -ne 0 ]; then
    setup
    config_current
    chmod 500 "$SYNOPKG_TEMP_UPGRADE_FOLDER"
    RUN=$((RUN + 1))
    if sh "$TREE/scripts/preupgrade" 2>/dev/null; then
        fail "update continued although the config could not be saved"
    elif [ -s "$SYNOPKG_TEMP_LOGFILE" ]; then
        pass "config cannot be saved: update refused, with a message for DSM"
    else
        fail "config cannot be saved: update refused, but DSM gets no message"
    fi
    teardown
else
    echo "  skip: config cannot be saved (running as root)"
fi

# The saved config cannot be put back. preupgrade makes this unlikely, but
# if it happens the update must not look successful.
if [ "$(id -u)" -ne 0 ]; then
    setup
    config_current
    sh "$TREE/scripts/preupgrade"
    rm -rf "$SYNOPKG_PKGDEST"
    mkdir -p "$SYNOPKG_PKGDEST/log"
    chmod 555 "$SYNOPKG_PKGDEST"
    RUN=$((RUN + 1))
    if sh "$TREE/scripts/postupgrade" 2>/dev/null; then
        fail "update reported success although the config could not be restored"
    elif grep -q "uninstall" "$SYNOPKG_TEMP_LOGFILE"; then
        pass "config cannot be restored: update fails, and DSM is told what to do"
    else
        fail "config cannot be restored: update fails, but the message doesn't say what to do"
    fi
    teardown
else
    echo "  skip: config cannot be restored (running as root)"
fi

echo
if [ "$FAIL" -eq 0 ]; then
    echo "All $RUN checks passed."
else
    echo "Some of the $RUN checks failed."
fi
exit "$FAIL"
