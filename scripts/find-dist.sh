#!/bin/bash
# Locate the zuma_shusky_dist artifacts from the successful build.
KSRC=/home/king/kernel-shusky

echo "=== build_shusky.sh ==="
cat "$KSRC/build_shusky.sh" 2>/dev/null

echo ""
echo "=== out/ top level ==="
ls -la "$KSRC/out" 2>/dev/null | head -40

echo ""
echo "=== key artifacts (depth<=5) ==="
find "$KSRC/out" -maxdepth 5 \( -name 'Image' -o -name 'Image.lz4' -o -name 'dtbo.img' -o -name 'vendor_dlkm.img' -o -name 'vendor_boot.img' -o -name 'init_boot.img' -o -name 'boot.img' -o -name '*.ko' -o -name 'System.map*' -o -name 'vmlinux' \) -printf '%p  %s bytes\n' 2>/dev/null | head -80

echo ""
echo "=== dist directories ==="
find "$KSRC" -maxdepth 6 -type d -name 'dist' -printf '%p\n' 2>/dev/null | head -20

echo ""
echo "=== find-dist done ==="
