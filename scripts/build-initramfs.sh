#!/usr/bin/env bash
# Assemble the initramfs the V86 sandbox boots into.
# Produces $1/initramfs.cpio.gz.
set -euo pipefail

OUT="${1:-out}"
CEFAS_VERSION="${CEFAS_VERSION:-latest}"
STAGE="build/rootfs"

mkdir -p "$STAGE" "$OUT"
rm -rf "$STAGE"
mkdir -p "$STAGE"/{bin,sbin,dev,proc,sys,tmp,etc/cefas,etc/init.d,usr/bin,usr/sbin,data,root}

docker build \
  --build-arg CEFAS_VERSION="$CEFAS_VERSION" \
  --build-arg CEFAS_TOKEN="${CEFAS_TOKEN:-}" \
  -f Dockerfile.rootfs \
  -t cefas-sandbox-rootfs:build .

cid="$(docker create cefas-sandbox-rootfs:build /bin/true)"
trap 'docker rm -f "$cid" >/dev/null' EXIT
docker cp "$cid:/rootfs/." "$STAGE/"

cp rootfs/init "$STAGE/init"
chmod 755 "$STAGE/init"
cp -r rootfs/etc/. "$STAGE/etc/"
# /root holds the cefas-cli profile so the user gets plaintext
# dialing out of the box, no flags required.
[ -d rootfs/root ] && cp -r rootfs/root/. "$STAGE/root/"

pushd "$STAGE" >/dev/null
  find . -print0 \
    | cpio --null -ov --format=newc 2>/dev/null \
    | gzip -9 > "../../$OUT/initramfs.cpio.gz"
popd >/dev/null

echo "✓ $OUT/initramfs.cpio.gz ($(du -h "$OUT/initramfs.cpio.gz" | cut -f1))"
