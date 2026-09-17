# Changelog

Changes to the **SpotConnect-Synology packaging** — installer scripts, build pipeline,
config handling. For changes to `spotupnp`/`spotraop` themselves, see the upstream
[SpotConnect CHANGELOG](https://github.com/philippe44/SpotConnect/blob/master/CHANGELOG)
(bundled in each release). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.20.8-20260917] - 2026-09-17

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
- A pre-flight check before starting either binary. It runs the binary once and, if it
  cannot run on this device, puts the real reason into the package log and into Package
  Center instead of a bare "Failed to start" with the cause buried in
  `/var/log/packages/`. It distinguishes a too-old libstdc++ (answer: install the
  `-static` package) from a binary that crashes outright (answer: this device cannot run
  this build), and reports the signal when a binary dies without printing anything.
- `tests/validate_elf.py` and `tests/validate_spk.sh`, carried over from
  AirConnect-Synology. `validate_elf.py` was extended to also collect `GLIBCXX_` and
  `CXXABI_` symbol versions, not just `GLIBC_`. That was a real gap rather than a nicety:
  `"GLIBCXX_3.4.29".startswith("GLIBC_")` is false, so the C++ requirements were silently
  dropped and the tool reported `max_glibc=2.17` — "runs anywhere" — for binaries that
  cannot start on DSM 7.1.
- CI: build and validate every architecture on each push and pull request; publish a
  release with `SHA256SUMS` on a tag; super-linter; a tokenless Semgrep scan; and a weekly
  upstream check that opens a version-bump PR when philippe44/SpotConnect publishes a new
  release. That last one exists because the sibling project sat two years behind upstream
  without anyone noticing. The bump PR is never auto-merged, and it names the Linux
  architectures present in the new upstream archive so a changed build matrix is visible
  before merging rather than after.
- Documentation: README plus `doc/OVERVIEW.md`, `doc/ARCHITECTURES.md`, `doc/CONFIG.md`,
  `doc/TROUBLESHOOTING.md`, `doc/BUILD.md`.

### Known issues

- **Some older devices cannot run SpotConnect 0.20.8 at all**, and this is upstream rather
  than packaging. The dynamic builds need `GLIBCXX_3.4.29`, which older DSM releases do
  not ship; the `-static` builds, which would otherwise solve that, terminate with
  `SIGSEGV` on startup on kernels below the 4.4.255 they declare. Measured: DS923+
  (DSM 7.4.1, kernel 4.4.302+) works; DS415+ (DSM 7.1.1, kernel 3.10.108) and RT2600ac
  (SRM 1.3.2, kernel 4.4.60) fail both ways. Reported as
  [SpotConnect#78](https://github.com/philippe44/SpotConnect/issues/78). The same crash
  affects AirConnect's static builds on the same hardware, so it is not specific to this
  project.
- Two smaller upstream reports from the same work:
  [#76](https://github.com/philippe44/SpotConnect/issues/76) (credential files written
  world-readable) and [#77](https://github.com/philippe44/SpotConnect/issues/77) (`-t`
  exits 1 on success).

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
