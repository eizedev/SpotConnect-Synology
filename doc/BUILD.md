# Building the package

This repository builds Synology `.spk` packages around **upstream's released binaries**.
It does not compile `spotupnp` or `spotraop`, and that is a deliberate constraint rather
than laziness — see [below](#why-the-binaries-are-not-built-here).

## Requirements

- `make`, `curl`, `tar`, GNU coreutils
- `shellcheck` for the lint target
- Python 3 for the ELF validator

## Getting the binaries

The pinned upstream release is recorded in [`upstream.json`](../upstream.json):

```json
{
  "version": "0.20.8",
  "tag": "0.20.8",
  "asset": "SpotConnect-0.20.8.zip",
  "sha256": "fad415ea437365bc1dd639d9255ec141a1d59c6e69f0f01a614cfa53e164f171"
}
```

Download that asset from
[upstream's releases](https://github.com/philippe44/SpotConnect/releases), **verify the
checksum**, and extract the Linux binaries into `src/dsm7/bin/`:

```sh
cd src/dsm7/bin
curl -L -O https://github.com/philippe44/SpotConnect/releases/download/0.20.8/SpotConnect-0.20.8.zip
shasum -a 256 SpotConnect-0.20.8.zip   # must match upstream.json
unzip -o SpotConnect-0.20.8.zip 'spotupnp-linux-*' 'spotraop-linux-*'
rm SpotConnect-0.20.8.zip
```

`src/dsm7/bin/` is git-ignored; binaries are never committed.

The checksum step is not ceremony. The sibling project shipped a release whose binaries
had been silently corrupted during unzip by its download tooling, and nobody noticed until
users reported it.

## Building

One architecture:

```sh
cd src/dsm7
ARCH=x86_64 make clean build
```

All of them:

```sh
cd src/dsm7
./build.sh
```

Packages land in `src/dsm7/dist/` as
`SpotConnect-dsm7-<arch>-<version>-<date>.spk`. Valid `ARCH` values are the Makefile
targets: `arm`, `armv5`, `aarch64`, `powerpc`, `x86`, `x86_64`, each with a `-static`
twin.

`build.sh` derives the architecture list from the Makefile itself rather than keeping its
own copy, so the two cannot drift apart.

The build fetches `LICENSE` and `CHANGELOG` from the **pinned tag**, not from `master`,
so a package never ships documentation describing a different build than its binaries.

## Checking the result

```sh
cd src/dsm7 && make shellcheck          # installer scripts and build.sh
../../tests/validate_spk.sh dist/*.spk  # package structure
../../tests/validate_elf.py --arch x86_64 bin/spotupnp-linux-x86_64 bin/spotraop-linux-x86_64
```

See [`tests/README.md`](../tests/README.md) for what each validator covers and, just as
importantly, what it cannot tell you.

## Installing a local build

Package Center → **Manual Install** → upload the `.spk`. DSM will warn that the publisher
is unknown; the package is not signed with a Synology developer certificate.

From a shell, `sudo synopkg install <file>.spk` works too, but the GUI path is what users
take and therefore the one worth testing.

## Why the binaries are not built here

Since version 0.20.0, SpotConnect needs a Spotify application `client_id` and
`client_secret` to reach the parts of Spotify's Web API it depends on. Upstream compiles
its own into the binaries it publishes, and the source tree carries only placeholders:

```c
/* spotupnp/src/client_info.h, spotraop/src/client_info.h */
#define CLIENT_ID "<your client id>"
#define CLIENT_SECRET "<your client secret>"
```

The file is tracked in git — it is not hidden — but it holds no working values. A build
made from source therefore has no usable credentials and will fail to authenticate. The
only way to ship something that works is to package the release binaries, which is what
this repository does.

If you want to build from source anyway, you need your own credentials from the
[Spotify developer dashboard](https://developer.spotify.com/), and then either compile
them in by editing `client_info.h`, or pass them at runtime with `-D` and `-S`, or set
`<client_id>` and `<client_secret>` in the config file. Upstream's
[README](https://github.com/philippe44/SpotConnect#compiling-from-source) covers the
build itself; note that it pulls several submodules including `cspot`.

## Updating to a new upstream release

1. Update `upstream.json`: version, tag, asset name and the real SHA256 of the downloaded
   asset.
2. Re-download and re-extract the binaries.
3. Re-check the architecture matrix against SynoCommunity's `spksrc` — see
   [ARCHITECTURES.md](ARCHITECTURES.md#keeping-this-list-current). Upstream sometimes adds
   or drops build targets.
4. Rebuild, run both validators.
5. Note the change in [`CHANGELOG.md`](../CHANGELOG.md).
