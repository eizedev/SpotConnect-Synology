# Security Policy

## What is in scope here

This repository is the **Synology packaging** around upstream
[SpotConnect](https://github.com/philippe44/SpotConnect). In scope:

- The installer and lifecycle scripts (`src/dsm7/scripts/`)
- The wizard files, package permissions and resource declarations
- How Spotify credentials are stored on disk
- The build and release pipeline, including how upstream binaries are fetched and verified

Vulnerabilities in `spotupnp` or `spotraop` themselves — the network protocol handling,
the Spotify client, the HTTP server — belong
[upstream](https://github.com/philippe44/SpotConnect/security). If you are unsure which
side a problem falls on, report it here and it will be routed.

## Reporting

Use GitHub's
[private vulnerability reporting](https://github.com/eizedev/SpotConnect-Synology/security/advisories/new)
rather than a public issue. Please include what an attacker would gain, what access they
need to start with, and the DSM version and model you observed it on.

Expect an initial response within a few days. This is a spare-time project, so please do
not read silence as dismissal — follow up if you have not heard back within a week.

## Known properties worth understanding before reporting

These are deliberate, documented trade-offs rather than oversights. Reports about them
are still welcome if you can show the reasoning is wrong.

**Spotify tokens are stored on disk.** Upstream writes `spotupnp-*.json` /
`spotraop-*.json` containing reusable, device-specific credentials, using a plain
`fopen(…, "w")` with no `chmod` and no `umask` — so the files themselves are typically
world-readable. This package cannot change how they are written, so it controls where
they go: a directory with mode `0700`, owned by the unprivileged `spotconnect` user the
daemons run as, re-asserted on every start. Anyone with root on the NAS can read them
regardless; that is inherent.

Upstream fixed the file mode in 0.20.9 ([#76](https://github.com/philippe44/SpotConnect/issues/76)),
verified on real hardware. This package still ships 0.20.8, so the description above is
what you get today; the restricted directory stays either way.

These tokens are device credentials issued by Spotify, not account credentials. They
cannot be used to sign in to the account. That is a reason to store them rather than a
password, not a reason to treat them casually.

**Spotify username and password are deliberately not supported**, although upstream
accepts `-U`/`-P`. A password passed on a command line is visible to every local user
through `ps`.

**The AirPlay device password is obfuscated, not encrypted.** Upstream's `-L` option
stores it in the config file as XOR plus Base64. Anyone who can read the file can recover
it. Treat it as unprotected.

**The package runs unprivileged.** `conf/privilege` declares `"run-as": "package"`, so
the daemons and the lifecycle scripts run as the `spotconnect` user, not root.

**No shared folder is created.** Unlike the sibling AirConnect-Synology package, nothing
here is placed in an SMB-reachable location. Config, logs and credentials stay inside the
package directory.

**Upstream binaries are pinned and checksummed.** `upstream.json` records the release tag
and the SHA256 of the release asset, and the build verifies it after download. The
binaries are not built from source, for the reason given in
[doc/BUILD.md](doc/BUILD.md#why-the-binaries-are-not-built-here); if you consider that
itself a supply-chain concern, it is a fair one to raise.

## Supported versions

Only the latest release. This project tracks upstream, and fixes ship in a new release
rather than as backports.
