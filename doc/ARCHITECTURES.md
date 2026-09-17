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

## Which variant — and the honest answer that some devices have none

Every architecture ships in two builds, dynamic and `-static`. Choosing between them is
unfortunately not a formality for this package, and on some older devices neither works.

Two independent constraints are in play.

### 1. The dynamic builds need a recent libstdc++

`spotupnp` and `spotraop` are C++ (upstream builds on cspot), and the dynamic builds
reference **`GLIBCXX_3.4.29`** — a libstdc++ symbol version that only exists from
libstdc++ 6.0.29 (GCC 11) onwards. DSM ships libstdc++ with the OS, so this is decided by
your DSM release:

```text
/volume1/@appstore/SpotConnect/spotupnp: /lib64/libstdc++.so.6:
version `GLIBCXX_3.4.29' not found (required by .../spotupnp)
```

### 2. The static builds crash on older kernels

The `-static` builds carry their own C and C++ libraries, which solves the above — but on
kernels below the 4.4.255 the binaries declare, they terminate with `SIGSEGV` immediately
on startup, before printing anything. Reported upstream as
[SpotConnect#78](https://github.com/philippe44/SpotConnect/issues/78).

### Measured on real hardware

| Device   | DSM/SRM   | Kernel   | libstdc++ | Dynamic        | `-static`  |
| -------- | --------- | -------- | --------- | -------------- | ---------- |
| DS923+   | DSM 7.4.1 | 4.4.302+ | 6.0.31    | **works**      | works      |
| DS415+   | DSM 7.1.1 | 3.10.108 | 6.0.25    | no (`GLIBCXX`) | no (crash) |
| RT2600ac | SRM 1.3.2 | 4.4.60   | older     | no (`GLIBCXX`) | no (crash) |

### So which do I install?

1. **Install the dynamic package first.** On a current DSM it simply works, and it is half
   the size.
2. **If it reports a missing `GLIBCXX` version, install the `-static` package instead.**
   This is the case it genuinely rescues: a device new enough to have a 4.4.255+ kernel but
   running a DSM release whose libstdc++ is too old.
3. **If the `-static` package then dies without a message, this device cannot run
   SpotConnect 0.20.8 at all.** That is not something the packaging can work around, and
   it is what upstream issue #78 is about.

You do not have to work this out by reading logs: the package checks before starting and
says which of these three cases you are in, in plain words, in Package Center and in its
own log.

To check in advance over SSH:

```sh
uname -r                                              # needs to be >= 4.4.255 for -static
grep -ao "GLIBCXX_3.4.29" /lib*/libstdc++.so.6 | head -1   # output means dynamic will load
```

The `-static` packages for `arm`, `aarch64` and `powerpc` additionally declare `noarch`,
which lets DSM offer them on platforms not otherwise listed.

## What the binaries require

Measured with [`tests/validate_elf.py`](../tests/validate_elf.py) against SpotConnect
0.20.8. Every dynamic build has the same requirements; only the machine type and
interpreter differ.

| Package       | Machine        | Linkage | Interpreter                   | Min. kernel | `GLIBC` | `GLIBCXX` |
| ------------- | -------------- | ------- | ----------------------------- | ----------- | ------- | --------- |
| `arm`         | arm 32-bit     | dynamic | `/lib/ld-linux-armhf.so.3`    | 4.4.255     | 2.17    | 3.4.29    |
| `armv5`       | arm 32-bit     | dynamic | `/lib/ld-linux.so.3`          | 4.4.255     | 2.17    | 3.4.29    |
| `aarch64`     | aarch64        | dynamic | `/lib/ld-linux-aarch64.so.1`  | 4.4.255     | 2.17    | 3.4.29    |
| `powerpc`     | powerpc 32-bit | dynamic | `/lib/ld.so.1`                | 4.4.255     | 2.17    | 3.4.29    |
| `x86`         | x86 32-bit     | dynamic | `/lib/ld-linux.so.2`          | 4.4.255     | 2.17    | 3.4.29    |
| `x86_64`      | x86_64         | dynamic | `/lib64/ld-linux-x86-64.so.2` | 4.4.255     | 2.17    | 3.4.29    |
| any `-static` | as above       | static  | none                          | 4.4.255     | n/a     | n/a       |

Note the interpreter difference between `arm` and `armv5`: hard-float versus soft-float.
That is why they are separate packages and not interchangeable.

**`GLIBCXX` is the column that decides whether the package runs**, and it is the one that
is easy to overlook — `GLIBC` 2.17 is ancient and satisfied everywhere, which makes the
binaries look far more portable than they are. This tool originally reported only the
`GLIBC` column and was extended after a real installation failed on a device it had
declared fine.

> **The "min. kernel" column, by contrast, tells you nothing useful.** It is the value in
> the binary's `.note.ABI-tag`. The sibling project AirConnect-Synology established on
> real hardware that whether a device actually hits glibc's `FATAL: kernel too old`
> depends on its current DSM patch level, not on its model, platform name or kernel
> version number — the same combination that failed for users in 2023 ran fine when
> re-tested later. Do not build a "supported devices" list from that column.

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
