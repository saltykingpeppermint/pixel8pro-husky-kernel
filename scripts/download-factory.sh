#!/bin/bash
# Download + verify + extract the stock husky factory image (Android 16 / baklava
# era, BP31.250610.009). The curl may already be running from an earlier launch;
# this script is idempotent: resumes, verifies SHA-256, extracts what packaging needs.
set -euo pipefail

DIR=/mnt/d/pixel8pro-factory
URL=https://dl.google.com/developers/android/baklava/images/factory/husky_beta-bp31.250610.009-factory-f8edd5b7.zip
SHA256=f8edd5b7a72c9a5d4bad64d5e70594fb2fab0ee6ef9c8b0ee46c324c905d5801
ZIP="$DIR/$(basename "$URL")"

mkdir -p "$DIR"

if [ ! -f "$ZIP" ]; then
    echo "[dl] missing — downloading..."
    curl -fL --retry 5 --retry-delay 10 -C - -o "$ZIP" "$URL"
else
    echo "[dl] present: $(du -h "$ZIP" | cut -f1) — resuming if incomplete"
    curl -fL --retry 5 --retry-delay 10 -C - -o "$ZIP" "$URL" || true
fi

echo "[sha] verifying against official checksum..."
echo "$SHA256  $ZIP" | sha256sum -c -

echo "[unzip] top level (flash-all + image zip)..."
unzip -o -q "$ZIP" "image-husky*" "flash-all.sh" "flash-all.bat" -d "$DIR"

IMGZIP=$(ls "$DIR"/image-husky*.zip | head -1)
echo "[unzip] partition images from $(basename "$IMGZIP")..."
unzip -o -q "$IMGZIP" boot.img dtbo.img init_boot.img vendor_boot.img \
    vbmeta.img vbmeta_system.img vbmeta_vendor.img -d "$DIR" \
    || unzip -o -q "$IMGZIP" -d "$DIR"

echo "== result =="
ls -la "$DIR"
echo "FACTORY IMAGE READY"
