#!/bin/bash
#
# Fetch the libstdc++ builds that are bundled with the dynamic packages.
#
# spotupnp/spotraop are C++ and need GLIBCXX_3.4.29, which older DSM
# releases do not ship (DSM 7.1.1 has libstdc++ 6.0.25). Putting a matching
# libstdc++ next to the binaries lets them run there - verified on a DS415+
# (DSM 7.1.1) and an RT2600ac (SRM 1.3.2). Only libstdc++ is bundled, never
# glibc: the device's own glibc is what matches its kernel.
#
# The libraries come from GLIB.xz in philippe44/cross-compiling, pinned by
# commit and SHA256 in ../../libstdcxx.json, exactly like upstream.json pins
# the SpotConnect release. Output: libstdcxx/<arch>/libstdc++.so.6
#
# Only the architectures listed under "members" are fetched. 32-bit ARM is
# deliberately absent: the only armv7 build in GLIB.xz predates the TLS fix
# in philippe44's toolchain, i.e. it is the configuration his own notes say
# crashes on C++ exceptions thrown in threads.

set -euo pipefail

cd "$(dirname "$0")"

PIN=../../libstdcxx.json
OUT=libstdcxx

for tool in jq curl tar; do
  command -v "$tool" >/dev/null || {
    echo "error: $tool is required" >&2
    exit 1
  }
done

sha256_of() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# llvm-strip handles ELF for every target architecture; GNU strip only its
# own, so it is the fallback for the host architecture and nothing else.
find_strip() {
  local s
  # Any version will do for stripping, so an unmatched glob simply falls
  # through to the next candidate.
  for s in llvm-strip /usr/lib/llvm-*/bin/llvm-strip \
    /opt/homebrew/opt/llvm/bin/llvm-strip /usr/local/opt/llvm/bin/llvm-strip; do
    if command -v "$s" >/dev/null 2>&1; then
      command -v "$s"
      return 0
    fi
  done
  return 1
}

REPO=$(jq -r .source_repo "$PIN")
COMMIT=$(jq -r .commit "$PIN")
FILE=$(jq -r .path "$PIN")
EXPECTED=$(jq -r .sha256 "$PIN")
URL="https://raw.githubusercontent.com/${REPO}/${COMMIT}/${FILE}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "Fetching ${REPO}@${COMMIT:0:7}:${FILE}"
curl -sfL -o "$WORK/archive.xz" "$URL"

ACTUAL=$(sha256_of "$WORK/archive.xz")
echo "expected: ${EXPECTED}"
echo "actual:   ${ACTUAL}"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "error: checksum mismatch - refusing to bundle this download" >&2
  exit 1
fi

STRIP=$(find_strip || true)
if [ -z "$STRIP" ]; then
  echo "warning: no llvm-strip found - bundling unstripped libraries (larger package)" >&2
fi

rm -rf "$OUT"
for arch in $(jq -r '.members | keys[]' "$PIN"); do
  member=$(jq -r --arg a "$arch" '.members[$a]' "$PIN")
  tar -xJf "$WORK/archive.xz" -C "$WORK" "$member"
  mkdir -p "$OUT/$arch"
  # Named after the SONAME the binaries actually ask for, so no symlink is
  # needed - symlinks inside package.tgz are one more thing to go wrong.
  cp "$WORK/$member" "$OUT/$arch/libstdc++.so.6"
  before=$(wc -c <"$OUT/$arch/libstdc++.so.6" | tr -d ' ')
  if [ -n "$STRIP" ]; then
    "$STRIP" --strip-unneeded "$OUT/$arch/libstdc++.so.6"
  fi
  after=$(wc -c <"$OUT/$arch/libstdc++.so.6" | tr -d ' ')
  chmod 644 "$OUT/$arch/libstdc++.so.6"
  printf '  %-8s %-40s %9s -> %9s bytes\n' "$arch" "$member" "$before" "$after"
done

echo "Done: $(find "$OUT" -name 'libstdc++.so.6' | wc -l | tr -d ' ') libraries in $OUT/"
