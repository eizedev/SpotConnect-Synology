# Tests

Two validators, both dependency-free so they run in CI without any install
step. Neither needs a Synology device.

| Script | Checks |
|---|---|
| `validate_elf.py` | Each packaged binary is a well-formed ELF for the architecture it is being shipped as, and reports its interpreter, minimum kernel and highest referenced glibc symbol version. |
| `validate_spk.sh` | A built `.spk` has every required member, an `INFO` with no unsubstituted `#PLACEHOLDER#` left in it, executable payload binaries, lifecycle scripts with shebangs, and valid icon PNGs. |

## Why these exist

Both are carried over from AirConnect-Synology, where their absence had a
concrete cost: a 2024 release shipped binaries that `release-downloader`
had silently corrupted while unzipping, and nothing in CI noticed until
users reported it (that project's issue #107). `validate_elf.py` alone would
have caught it, because a corrupted file does not start with the ELF magic.

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

## Not covered here

Runtime behaviour. Whether a speaker actually appears in the Spotify app,
whether playback survives the controlling phone leaving the network, and how
much CPU re-encoding costs on an older NAS can only be answered on real
hardware - see the project documentation for what has been verified on which
device, and what has not.
