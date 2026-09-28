# Tests

Two validators and two lifecycle simulations, all dependency-free so they run in CI without
any install step. None needs a Synology device.

| Script                 | Checks                                                                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `validate_elf.py`      | Each packaged binary is a well-formed ELF for the architecture it is being shipped as, and reports its interpreter, minimum kernel and highest referenced glibc symbol version.                                                                                                                                                                                                                                     |
| `upgrade_state.sh`     | What an update does to an existing installation: settings, edited `config-*.xml`, stored Spotify sign-ins and their directory mode, the "forget sign-ins" choice, backfilling keys an older config lacks, and refusing the update when the settings cannot be carried over.                                                                                                                                         |
| `start_stop_status.sh` | What `status`/`stop`/`start` report and do when the config is missing, one program died, both are switched off, or a foreign process has the same name.                                                                                                                                                                                                                                                             |
| `validate_spk.sh`      | A built `.spk` has every required member; an `INFO` whose mandatory fields (`package`, `version`, `description`, `arch`, `maintainer`, `os_min_ver`, `changelog`) are all non-empty and free of unsubstituted `#PLACEHOLDER#`s; executable payload binaries; a bundled libstdc++ matching the package's architecture, with its licence, where one is present; lifecycle scripts with shebangs; and valid icon PNGs. |

## Why these exist

Both are carried over from AirConnect-Synology, where their absence had a
concrete cost: a 2024 release shipped binaries that `release-downloader`
had silently corrupted while unzipping, and nothing in CI noticed until
users reported it (that project's issue #107). `validate_elf.py` alone would
have caught it, because a corrupted file does not start with the ELF magic.

## The `changelog` field

`changelog` is generated at build time by `src/dsm7/info_changelog.sh` and is what Package
Center shows as "What's New" next to an available update. It is built from the newest
released section of this repository's `CHANGELOG.md` plus upstream's entries for the
bundled version, so an empty or missing one means the build lost that text - which is why
`validate_spk.sh` treats it as mandatory rather than optional.

## Usage

```sh
# Binaries, per architecture (names match the Makefile's targets)
tests/validate_elf.py --arch x86_64 src/dsm7/bin/spotupnp-linux-x86_64 \
                                    src/dsm7/bin/spotraop-linux-x86_64

# Built packages
tests/validate_spk.sh src/dsm7/dist/*.spk
```

Exit status is 0 when every hard check passes. Findings that are descriptive
rather than pass/fail (minimum kernel, glibc versions, float ABI) are printed
but never fail a run on their own.

## What `min_kernel` does and does not tell you

`validate_elf.py` reports the minimum kernel declared in the binary's
`.note.ABI-tag`. **Do not build a compatibility table or an `arch=` exclusion
list from it.** AirConnect-Synology established, on real hardware, that
whether a device hits glibc's "FATAL: kernel too old" depends on that
device's current DSM patch level rather than on its model, platform name or
kernel version number - the same kernel/glibc combination that failed for
users in 2023 ran fine when re-tested later. Treat the value as diagnostic
output, nothing more.

## `start_stop_status.sh`

Runs `start-stop-status` against the states an installation can really be in: healthy,
one of two programs dead, both switched off, config missing while the programs run,
config missing with nothing running, and processes with the same names that belong to
something else. Stand-in processes are small scripts named `spotupnp`/`spotraop` in a
throwaway package directory, so they match the path-based process lookup exactly as the
real binaries do. Checked: what `status` reports (0 running, 3 stopped, 150 broken), that
`stop` works without a config, that `start` without a config refuses with a message, and
that `start` first stops a program left over from a partial crash.

Ported from AirConnect-Synology, where the config-missing state showed up on real
hardware. Run it with `sh tests/start_stop_status.sh`; each `stop` waits the script's own
10 seconds, so a run takes a little under a minute.

## `upgrade_state.sh`

Prepares a throwaway installation, sets the `SYNOPKG_*` variables DSM sets, then runs
`preupgrade`, the upgrade wizard and `postupgrade` against it. Between the two scripts it
empties the package directory, as DSM does when it swaps in the new package, so anything
`preupgrade` failed to save shows up as lost.

The keys a fresh install writes are read from `postinst`, so a key added there without a
backfill in `postupgrade` fails the run. The two scenarios that make a copy fail through
file permissions are skipped when running as root.

Ported from AirConnect-Synology, whose `doc/CONVENTIONS.md` ("Updates") holds the rule it
checks. Run it with `sh tests/upgrade_state.sh`; it needs nothing but a POSIX shell.

## Not covered here

Runtime behaviour. Whether a speaker actually appears in the Spotify app,
whether playback survives the controlling phone leaving the network, and how
much CPU re-encoding costs on an older NAS can only be answered on real
hardware - see the project documentation for what has been verified on which
device, and what has not.
