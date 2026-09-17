# Architectures

Which `.spk` to install, why there is a `-static` variant, and why some architectures
upstream ships are not packaged here.

## Picking a package

If you have any recent Intel or AMD based NAS, take **`x86_64`**. That covers the large
majority of Synology devices. Otherwise look your model's platform up on Synology's
[What kind of CPU does my Synology NAS have?](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Compatibility_Peripherals/What_kind_of_CPU_does_my_NAS_have)
page and match it below.

| Package   | Synology platform codes                                                                                                                                                                                                                                           |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `x86_64`  | `x86_64` `x64` `cedarview` `bromolow` `avoton` `braswell` `broadwell` `apollolake` `dockerx64` `epyc7002` `r1000` `r1000nk` `kvmx64` `denverton` `grantley` `broadwellnk` `broadwellnkv2` `broadwellntbap` `v1000` `v1000nk` `geminilake` `geminilakenk` `purley` |
| `x86`     | `x86` `cedarview` `bromolow` `evansport` `braswell` `broadwell` `dockerx64` `kvmx64` `denverton` `grantley` `broadwellnk` `broadwellntbap`                                                                                                                        |
| `arm`     | `ipq806x` `armada370` `armadaxp` `armada375` `armada38x` `alpine` `alpine4k` `monaco` `comcerto2k` `hi3535` `dakota` `northstarplus` `hawkeye`                                                                                                                    |
| `armv5`   | `88f6282` `88f6281` `88f628x`                                                                                                                                                                                                                                     |
| `aarch64` | `rtd1296` `rtd1619b` `armada37xx` `cypress`                                                                                                                                                                                                                       |
| `powerpc` | `qoriq` `ppc853x`                                                                                                                                                                                                                                                 |

**Synology Routers (SRM)** run the ARM platforms: `ipq806x` (RT2600ac), `northstarplus`,
`dakota`, `hawkeye` (WRX560) use the `arm` package; `cypress` (RT6600ax) uses `aarch64`.

All packages declare `os_min_ver` 7.0-40000, i.e. **DSM 7 and newer**. There is no DSM 5/6
line for this package.

## The `-static` variant

Every architecture also has a `-static` package. The binaries inside it carry their own C
library instead of using the one on your device.

Install the normal one first. Use `-static` if the normal one fails to start with an
error about the kernel or a missing library version — that is precisely what it is for.
The trade-off is size (roughly twice as large) and that it cannot pick up security fixes
to your system's libc, so it is a fallback rather than the default.

The `-static` packages for `arm`, `aarch64` and `powerpc` additionally declare `noarch`,
which lets DSM offer them on platforms not otherwise listed.

## What the binaries require

Measured with [`tests/validate_elf.py`](../tests/validate_elf.py) against SpotConnect
0.20.8. These values are **diagnostic, not a compatibility promise** — see the warning
below.

| Package       | Machine        | Linkage | Interpreter                   | Declared min. kernel | Highest glibc referenced |
| ------------- | -------------- | ------- | ----------------------------- | -------------------- | ------------------------ |
| `arm`         | arm 32-bit     | dynamic | `/lib/ld-linux-armhf.so.3`    | 4.4.255              | 2.17                     |
| `armv5`       | arm 32-bit     | dynamic | `/lib/ld-linux.so.3`          | 4.4.255              | 2.17                     |
| `aarch64`     | aarch64        | dynamic | `/lib/ld-linux-aarch64.so.1`  | 4.4.255              | 2.17                     |
| `powerpc`     | powerpc 32-bit | dynamic | `/lib/ld.so.1`                | 4.4.255              | 2.17                     |
| `x86`         | x86 32-bit     | dynamic | `/lib/ld-linux.so.2`          | 4.4.255              | 2.17                     |
| `x86_64`      | x86_64         | dynamic | `/lib64/ld-linux-x86-64.so.2` | 4.4.255              | 2.17                     |
| any `-static` | as above       | static  | none                          | 4.4.255              | n/a                      |

Note the interpreter difference between `arm` and `armv5`: hard-float versus soft-float.
That is why they are separate packages and not interchangeable.

> **The "declared min. kernel" column does not tell you whether the package will run on
> your device.** It is the value in the binary's `.note.ABI-tag`. Its sibling project
> AirConnect-Synology established on real hardware that whether a device actually hits
> glibc's `FATAL: kernel too old` depends on that device's current DSM patch level, not
> on its model, platform name or kernel version number — the same kernel and glibc
> combination that failed for users in 2023 ran fine when re-tested later. Do not build a
> "supported devices" list from this table. If your device runs it, it runs it; if it
> does not, try `-static`.

## Why some upstream architectures are not packaged

Upstream's release zip contains more Linux builds than this repository packages. The ones
left out, and why:

- **`armv6`** — no Synology device is ARMv6 in Synology's or SynoCommunity's platform
  taxonomy. The Kirkwood devices people assume are ARMv6 are ARMv5 and are covered by the
  `armv5` package. AirConnect-Synology shipped an `armv6` package for years, investigated
  it, and removed it for this reason.
- **`mips`, `sparc64`** — no Synology DSM 7 or SRM platform uses either.
- **`freebsd-*`, `macos*`, `*.exe`, `solaris-*`** — not Synology targets.

Two PPC platform codes that exist in SynoCommunity's list are also deliberately absent
from the `powerpc` package: `ppc824x` and `ppc854x`. They are real, but no device using
them ever ran DSM 7, which is this package's minimum.

## Keeping this list current

The platform lists come from SynoCommunity's
[`spksrc`](https://github.com/SynoCommunity/spksrc/blob/master/mk/spksrc.common/archs.mk),
verified 2026-09-17. They drift as Synology ships new models, and a missing platform code
means owners of that model cannot see the package in Package Center at all — the binary
would run fine, they just never get offered it.

Re-check before any release that bumps the pinned upstream version: fetch the current
`archs.mk`, diff its `x64_ARCHS` / `ARMv5_ARCHS` / `ARMv7_ARCHS` / `ARMv8_ARCHS` /
`PPC_ARCHS` / `SRM_*_ARCHS` groups against the `INFO_ARCH` lines in
[`src/dsm7/Makefile`](../src/dsm7/Makefile), and translate any new codes into actual model
names before deciding.
