# Changelog

Changes to the **SpotConnect-Synology packaging** — installer scripts, build pipeline,
config handling. For changes to `spotupnp`/`spotraop` themselves, see the upstream
[SpotConnect CHANGELOG](https://github.com/philippe44/SpotConnect/blob/master/CHANGELOG)
(bundled in each release). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

Initial packaging. Nothing released yet.

### Added

- DSM 7 package built around upstream SpotConnect 0.20.8, pinned in `upstream.json` with
  a SHA256 checksum verified against the downloaded asset. Twelve architecture packages:
  `arm`, `armv5`, `aarch64`, `powerpc`, `x86`, `x86_64`, each with a `-static` twin.
- Install wizard for choosing `spotupnp`, `spotraop` or both, the bind address and the
  UPnP port.
- Reusable Spotify sign-ins stored via upstream's `-J` into a package-private directory
  with mode `0700`, owned by the unprivileged `spotconnect` user. Upstream writes those
  files with no `chmod` of its own, so the directory is what protects them. The path is
  derived rather than configurable, so it cannot be pointed at a shared folder.
- Upgrade wizard option to forget stored sign-ins, for switching Spotify accounts or
  re-acquiring a token that stopped working. The step is skipped when nothing is stored.
- Config and stored sign-ins survive package upgrades.
- Tuned defaults so nothing has to be looked up: bitrate 320 (upstream defaults to 160),
  fixed HTTP/RTP port ranges for firewall rules, and ports chosen to stay clear of
  AirConnect on the same NAS.
- `tests/validate_elf.py` and `tests/validate_spk.sh`, carried over from
  AirConnect-Synology.
- Documentation: README plus `doc/OVERVIEW.md`, `doc/ARCHITECTURES.md`, `doc/CONFIG.md`,
  `doc/TROUBLESHOOTING.md`, `doc/BUILD.md`.

### Notes on things done differently from AirConnect-Synology

- **No shared folder**, not even as an option. Reusable Spotify tokens must not sit in an
  SMB share.
- **No username/password option**, although upstream offers `-U`/`-P`. Anything on a
  command line is readable by every local user through `ps`.
- **Separate command lines per binary.** `-l` means flow mode in `spotupnp` but Apple TV
  pairing in `spotraop`; `-b` takes a port in one and not the other; `-g` exists in one
  only. Sharing an argument builder between them would be a real bug, not untidiness.
- **Process lookup determines the `ps` invocation and its PID column together**, and
  prefers `ps w` over bare `ps` on BusyBox. Both were found the hard way in the sibling
  project — see its PR #237.
- **No DSM 5/6 line.** New package, no existing users to keep on an older branch.
