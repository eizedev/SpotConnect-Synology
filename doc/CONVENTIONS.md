# Packaging conventions

This repository follows the packaging conventions of its sibling
[AirConnect-Synology](https://github.com/eizedev/AirConnect-Synology): same repository
layout, same build and release mechanics, same checks, same changelog and commit
conventions. Both wrap pre-built binaries from a
[philippe44](https://github.com/philippe44) project into Synology `.spk` packages, so a
fix found on real hardware for one is usually a fix for the other, and keeping the two
alike is what makes that transfer cheap.

**[AirConnect-Synology's doc/CONVENTIONS.md](https://github.com/eizedev/AirConnect-Synology/blob/HEAD/doc/CONVENTIONS.md)
describes the shared part, and is the reference.** This page lists only where this
repository departs from it, and why. If something here contradicts that document without
appearing below, that is a bug in one of the two — please open an issue rather than
guessing which one is right.

## Deliberate differences

### The package itself

**No shared folder, not even as an option.** AirConnect-Synology can place its config in
a DSM shared folder so it is editable over SMB. This package stores reusable Spotify
tokens; anything that can sign in to a speaker on your behalf does not belong in a share
that every household member can browse. Config and credentials stay in the package's own
directory, credentials in a `0700` subdirectory owned by the package user.

**No username/password option**, although upstream offers `-U`/`-P`. A password on a
command line is readable by every local user through `ps` — the same `ps` this package's
own process lookup uses. Since upstream obtains reusable tokens automatically after the
first playback, nobody has to type a password at all, so the option buys nothing and
costs a secret.

**Separate command lines per binary.** `spotupnp` and `spotraop` do not share an argument
builder, and must not. `-l` means flow mode in one and Apple TV pairing in the other, `-b`
takes a port in one but not the other, and `-g` exists in one only. AirConnect's script
can branch over its binaries because they take the same options; here that would be a
real bug rather than untidiness.

**No DSM 5/6 line, so no `src/dsm` tree.** New package, no existing users to keep on an
older branch. The commit scopes are therefore `dsm7`, `ci`, `doc` and `pkg` — the shared
list also carries `dsm6`, which has no meaning here.

**No `postuninst` script.** It exists in AirConnect-Synology to clean up the shared folder
it may have created. This package creates nothing outside its own directory, so once DSM
removes that directory there is nothing left to clean up, and an empty script would only
suggest otherwise.

### Build and release

**A bundled libstdc++, pinned in `libstdcxx.json`.** `spotupnp` and `spotraop` need
`GLIBCXX_3.4.29`, which DSM only ships from later 7.x releases, so the dynamic `x86_64`,
`x86` and `aarch64` packages carry a matching library and use it only when the device's
own is too old. AirConnect's binaries are C and need nothing of the sort. The pin file
works like `upstream.json` — commit plus SHA256, verified at build time — and the
library's licence and source pointer ship with it, since it is GPLv3 object code. See
`src/dsm7/fetch-libstdcxx.sh` and `src/dsm7/libstdcxx-licence/README.md`.

**`upstream.json`'s `tag` and `version` are used for different things.** In
AirConnect-Synology the two fields hold the same string, so nothing distinguishes them.
Upstream SpotConnect publishes pre-release tags such as `0.20.9-0` that carry version
`0.20.9`, so here the files are fetched from the **tag**, while the package version and
the "What's New" text use the **version** — which is what upstream's own `CHANGELOG`
lists its entries under, and what the release tag is built from. `RELEASE_VERSION`
overrides the version for a local build; CI does not set it.

**The default branch is `main`**, not `master`. Nothing in the tooling depends on the
name: changelog links use `blob/HEAD`, which resolves to whichever branch a repository
calls its default.

**An extra document, `doc/OVERVIEW.md`.** What AirConnect does is clear from one sentence.
What a Spotify Connect bridge does, and why you might want one when your speakers already
appear in the Spotify app via AirConnect, is not — so the reasoning gets its own page
instead of a longer README.

## Not differences, just gaps

AirConnect-Synology also runs a pull request labeler
(`.github/workflows/label.yml`, `.github/labeler.yml`), an image workflow and a
`CODEOWNERS` file. There is no reason against them here; they are simply not set up yet.
