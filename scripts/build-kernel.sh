#!/usr/bin/env bash
# Build a stripped Linux kernel for the V86 sandbox.
# Produces $1/bzImage.
set -euo pipefail

OUT="${1:-out}"
KVER="$(cat kernel/VERSION | tr -d '[:space:]')"
SRC="build/linux-${KVER}"

mkdir -p build "$OUT"

if [[ ! -d "$SRC" ]]; then
  tarball="linux-${KVER}.tar.xz"
  url="https://cdn.kernel.org/pub/linux/kernel/v${KVER%%.*}.x/${tarball}"
  echo "→ fetching ${tarball}"
  curl -sSfL "$url" -o "build/${tarball}"
  tar -xJf "build/${tarball}" -C build
fi

pushd "$SRC" >/dev/null
  # V86 emulates a 32-bit (i686) CPU — its WASM core has no x86_64
  # support. i386_defconfig is the matching upstream config and
  # already enables serial/vgacon/initramfs/8250. Overlay narrows it.
  make ARCH=i386 i386_defconfig
  cat ../../kernel/config.tiny >> .config
  make ARCH=i386 olddefconfig
  make ARCH=i386 -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" bzImage
popd >/dev/null

cp "$SRC/arch/x86/boot/bzImage" "$OUT/bzImage"
echo "✓ $OUT/bzImage ($(du -h "$OUT/bzImage" | cut -f1))"
