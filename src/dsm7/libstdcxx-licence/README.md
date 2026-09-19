# Bundled libstdc++

Some packages include `lib/libstdc++.so.6`, the GNU C++ standard library, so that
`spotupnp` and `spotraop` can run on devices whose DSM ships a libstdc++ too old for them.
It is only used when the device's own libstdc++ is not enough; the package checks that at
start and otherwise leaves the system library in charge.

## Licence

libstdc++ is part of GCC and is licensed under the **GNU General Public License, version 3**
(`COPYING3`) with the **GCC Runtime Library Exception, version 3.1** (`COPYING.RUNTIME`).
Both texts are included here, taken from the GCC 11.2.0 source tree.

The exception covers `spotupnp` and `spotraop` using this library: they keep their own
licence. The library itself remains GPLv3, which is why its licence and the location of
its source travel with it.

## Source

This build identifies itself as `GCC: (crosstool-NG 1.25.0) 11.2.0`.

- **GCC 11.2.0 source:** <https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/>
- **Build configuration** (crosstool-NG 1.25.0, per architecture):
  <https://github.com/philippe44/cross-compiling/tree/c836c90899159f74225ab5357ac9c23d44ec2067/crosstools-ng-1.25.0>
- **The prebuilt archive the library is taken from:**
  <https://github.com/philippe44/cross-compiling/blob/c836c90899159f74225ab5357ac9c23d44ec2067/GLIB.xz>
  (SHA256 `8fad036a8dcf5b89394ed5ee0581700c818af3fa6bd08281b6fae7da1a5135d5`)

In released packages the library is that file with debugging symbols removed
(`llvm-strip --strip-unneeded`) to reduce its size; the code is unchanged. A package built
locally without `llvm-strip` carries it unmodified.

Built by philippe44 for his [cross-compiling](https://github.com/philippe44/cross-compiling)
toolchain, which also builds the SpotConnect release binaries.
