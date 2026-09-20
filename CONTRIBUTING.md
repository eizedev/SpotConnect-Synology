# Contributing

Thanks for looking. This repository packages
[SpotConnect](https://github.com/philippe44/SpotConnect) for Synology devices — it does
not contain SpotConnect itself.

## Which repository does your issue belong to?

**Here** — installing, starting, stopping, upgrading or uninstalling the package; the
wizard; `spotconnect.conf`; where files and credentials are placed; the architecture
matrix; the build.

**[Upstream](https://github.com/philippe44/SpotConnect/issues)** — playback behaviour,
protocol handling, a specific speaker's quirks, audio quality, discovery internals,
anything about `spotupnp`/`spotraop` as programs.

If you cannot tell, open it here.

## Building and testing

See [doc/BUILD.md](doc/BUILD.md). In short:

```sh
cd src/dsm7
ARCH=x86_64 make clean build
make shellcheck
../../tests/validate_spk.sh dist/*.spk
```

Both validators are dependency-free and need no Synology device. What they cannot tell
you is whether the thing actually works, which is why real-hardware testing is called out
separately in the PR template.

## Conventions

Packaging conventions are shared with the sibling project
[AirConnect-Synology](https://github.com/eizedev/AirConnect-Synology/blob/HEAD/doc/CONVENTIONS.md);
[doc/CONVENTIONS.md](doc/CONVENTIONS.md) records where this repository deliberately
departs from them, and why. The short version:

- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `ci:`, `build:`, `test:`, `chore:`.
  Scopes used here are `dsm7`, `ci`, `doc`, `pkg`.
- **Feature branches**, named after the commit type they carry (`fix/...`, `docs/...`).
- **Everything in this repository is English** — code, comments, docs, wizard text,
  commit messages.
- Installer scripts are POSIX `sh`, not bash, and must pass `shellcheck -s sh`. DSM has no
  `pgrep`, and SRM uses BusyBox, so GNU-only behaviour cannot be assumed anywhere.
- Markdown is formatted by Prettier; `.markdownlint.json` is configured to agree with it.

## Two things that are easy to get wrong

**`spotupnp` and `spotraop` are not interchangeable.** The same option letter means
different things in each — `-l` is flow mode in one and Apple TV pairing in the other,
`-b` takes a port in one but not the other, `-g` exists in one only. Never share an
argument builder between them. See [doc/CONFIG.md](doc/CONFIG.md).

**DSM and SRM differ in ways that are not obvious.** Which `ps` invocation lists all
processes, which column holds the PID, and whether the command line is truncated all vary
between them. If you touch process handling, say in the PR whether you tested on a router
as well as a NAS.

## Changing a default

Defaults in `postinst` are written into every user's config file. Changing one later means
adding migration logic to `postupgrade` for everyone who already has the old value, so
they are worth getting right rather than adjusting casually. If a default is wrong,
please say what you measured and on what hardware.

## Security

Do not open a public issue for a vulnerability — see [SECURITY.md](SECURITY.md).
