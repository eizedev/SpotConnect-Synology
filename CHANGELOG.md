# Changelog

Changes to the **SpotConnect-Synology packaging** — installer scripts, build pipeline,
config handling. For changes to `spotupnp`/`spotraop` themselves, see the upstream
[SpotConnect CHANGELOG](https://github.com/philippe44/SpotConnect/blob/master/CHANGELOG)
(bundled in each release). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

The first sentence of each entry in the newest release section becomes the "What's New"
text Package Center shows for an update (see `src/dsm7/info_changelog.sh`), so lead with
what changes for the person installing it. Only the Keep a Changelog categories
(`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`) and `Known issues`
are used; changes that don't affect the installed package go under `### Internal`, which
is left out of that text like any other subsection.

## [Unreleased]

### Added

- **Older DSM releases can now run the package.** SpotConnect needs `GLIBCXX_3.4.29`, which
  DSM only ships from later 7.x releases, and the `-static` builds are no way out on older
  kernels ([SpotConnect#78](https://github.com/philippe44/SpotConnect/issues/78)). The
  dynamic `x86_64`, `x86` and `aarch64` packages now bundle a matching libstdc++, and
  `start-stop-status` switches to it only when the device's own is too old - decided by an
  actual run, not by comparing versions, so a current DSM keeps its system library. Verified
  end to end on a DS415+ with DSM 7.1.1, which previously could run neither build: installed
  through Package Center, started, played. Adds roughly half a megabyte per package; the
  library is stripped in CI from about 12 MB to about 1.7 MB.

  Pinned by commit and SHA256 in `libstdcxx.json`, like `upstream.json`. Only libstdc++ is
  bundled, never glibc. Ships with its licence (GPLv3 with the GCC Runtime Library
  Exception) and a pointer to its exact source. `validate_spk.sh` checks the library
  matches its package's architecture, and CI fails if a package's library presence
  disagrees with the pin file. Not bundled for `arm` (the only available build predates a
  thread-safety fix in the upstream toolchain), `armv5` or `powerpc` (untested).

### Internal

- `doc/CONVENTIONS.md` records where this package deliberately departs from
  AirConnect-Synology, whose own `doc/CONVENTIONS.md` describes the conventions the two
  share. The design notes that used to sit at the bottom of this file moved there, so the
  information exists in one place.
- The package version is now read from `upstream.json`'s `version` field instead of being
  passed in as the upstream tag. Both are the same string today, but upstream publishes
  pre-release tags such as `0.20.9-0` that carry version `0.20.9`, and the release tag was
  already built from `version` - so a release would have shipped a git tag and a package
  version that disagreed.
- `build.sh` now lists the packages it actually built instead of printing an example
  filename with the project name, architecture and version typed into it.
- Package Center now shows a "What's New" text for an update, generated at build time by
  `src/dsm7/info_changelog.sh` from the newest released section of this file plus
  upstream's entries for the bundled version. Taken over unchanged from
  AirConnect-Synology so both projects behave identically; everything project-specific is
  an argument, and the Makefile derives names and URLs from `INFO` and `upstream.json`
  rather than repeating them. `validate_spk.sh` now treats `INFO`'s `changelog` field as
  mandatory, so a build that loses the text fails instead of shipping quietly.
- Documentation: troubleshooting now covers a speaker appearing twice in Spotify when
  SpotConnect runs on two machines on the same network.
- The release and release-date badges showed "no releases or repo not found" even though a
  release existed: GitHub's "latest release" deliberately skips pre-releases, and so do the
  default shields.io badges. They now use `?include_prereleases` and the `release-date-pre`
  variant, and links point at the releases list rather than through `/releases/latest`.
- A tag ending in `-pre`, `-rc*`, `-beta*` or `-alpha*` now publishes as a GitHub
  pre-release on its own. The first one had to be marked by hand after the fact.

## [0.20.8-20260917-pre] - 2026-09-17

First release, deliberately published as a **pre-release**. The packaging is complete and
verified end to end on a DS923+ (DSM 7.4.1), but compatibility beyond that one device is
largely unmeasured, and an upstream problem decides whether older Synology hardware can run
this build at all - see Known issues below.

### Added

- DSM 7 package for upstream SpotConnect 0.20.8. The pinned release is verified against a
  SHA256 checksum before anything is built from it. Twelve architecture packages:
  `arm`, `armv5`, `aarch64`, `powerpc`, `x86`, `x86_64`, each with a `-static` twin.
- Install wizard for choosing `spotupnp`, `spotraop` or both, the bind address and the
  UPnP port.
- Spotify sign-ins are stored so speakers stay in your device list, in a package-private
  directory only this package can read. Upstream writes those
  files with no `chmod` of its own, so the directory is what protects them. The path is
  derived rather than configurable, so it cannot be pointed at a shared folder.
- Upgrade wizard option to forget stored sign-ins, for switching Spotify accounts or
  re-acquiring a token that stopped working. The step is skipped when nothing is stored.
- Config and stored sign-ins survive package upgrades.
- Tuned defaults, so nothing has to be looked up. Bitrate 320 where upstream defaults to
  160, fixed HTTP/RTP port ranges for firewall rules, and ports chosen to stay clear of
  AirConnect on the same NAS.
- The package now says why it cannot start, instead of a bare "Failed to start". It runs
  the binary once before starting it and, if it
  cannot run on this device, puts the real reason into the package log and into Package
  Center instead of a bare "Failed to start" with the cause buried in
  `/var/log/packages/`. It distinguishes a too-old libstdc++ (answer: install the
  `-static` package) from a binary that crashes outright (answer: this device cannot run
  this build), and reports the signal when a binary dies without printing anything.

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
  Upstream has looked at it and has no fix yet, having not changed its build tools.
- Three smaller upstream issues found while packaging are already fixed in SpotConnect
  0.20.9. That release is still a pre-release upstream, so this package continues to ship
  0.20.8 and the behaviour below is what it has today:
  [#76](https://github.com/philippe44/SpotConnect/issues/76) credential files written
  world-readable (the package's `0700` directory covers this, and will remain as a second
  layer), [#77](https://github.com/philippe44/SpotConnect/issues/77) `-t` exiting 1 on
  success, and [#79](https://github.com/philippe44/SpotConnect/issues/79) the built-in
  Spotify client credentials being written into generated config files in clear text.

### Internal

Not part of the installed package, so none of this reaches Package Center.

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

Where this package deliberately differs from AirConnect-Synology — no shared folder, no
username/password option, a separate command line per binary, no DSM 5/6 line — is
recorded in [doc/CONVENTIONS.md](doc/CONVENTIONS.md), with the reason for each.
