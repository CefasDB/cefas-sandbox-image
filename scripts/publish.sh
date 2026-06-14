#!/usr/bin/env bash
# Upload bzImage + initramfs.cpio.gz to the bucket fronting
# sandbox.cefasdb.com. CI calls this on release tags; for local
# publishes export AWS_PROFILE first.
set -euo pipefail

OUT="${1:-out}"
BUCKET="${SANDBOX_BUCKET:-cefas-sandbox-assets}"
PREFIX="${SANDBOX_PREFIX:-img}"

for f in bzImage initramfs.cpio.gz; do
  [[ -f "$OUT/$f" ]] || { echo "missing $OUT/$f — run make first"; exit 1; }
done

aws s3 cp "$OUT/bzImage"            "s3://$BUCKET/$PREFIX/bzImage"            --content-type application/octet-stream --cache-control "public,max-age=31536000,immutable"
aws s3 cp "$OUT/initramfs.cpio.gz"  "s3://$BUCKET/$PREFIX/initramfs.cpio.gz"  --content-type application/gzip          --cache-control "public,max-age=31536000,immutable"

echo "✓ published to s3://$BUCKET/$PREFIX/"
