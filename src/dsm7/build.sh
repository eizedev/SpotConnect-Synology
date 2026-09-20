#!/bin/bash

echo "[$(date +%Y-%m-%d" "%H:%M:%S)] #### Start BUILD... ####"

rm -r -f dist

set -eu

# Derived from the Makefile itself (every target that sets INFO_ARCH is a
# real architecture build) rather than kept as a second hand-maintained copy
# of the list - in AirConnect-Synology a separate hardcoded list was exactly
# what broke CI when an architecture was removed from the Makefile.
# The bundled libstdc++ is fetched separately (network, ~68 MB download).
# Without it the dynamic x86_64/x86/aarch64 packages still build, but will
# not start on devices whose DSM ships an older libstdc++ - so say so rather
# than silently producing a different package than CI does.
if [ ! -d libstdcxx ]; then
  echo "warning: libstdcxx/ is missing - run ./fetch-libstdcxx.sh first, or the dynamic" >&2
  echo "         packages will lack the bundled libstdc++ that older DSM releases need." >&2
fi

ARCH_LIST=$(awk '/^\.PHONY: /{t=$2} /INFO_ARCH=/{print t}' Makefile)
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH="${arch}"
  $MAKE clean build
done

rm -r -f target

echo
echo "[$(date +%Y-%m-%d" "%H:%M:%S)] #### Build complete, packages are in the dist directory"

ls -1 dist/*.spk

echo
echo "To install one on a Synology device from the command line, pick the package"
echo "matching your model (see doc/ARCHITECTURES.md):"
echo "  sudo synopkg install <one of the files above>"
