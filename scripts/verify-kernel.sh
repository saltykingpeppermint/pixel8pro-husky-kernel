#!/bin/bash
# Verify the freshly built dist artifacts before packaging boot.imgs:
#  - Image present
#  - CONFIG_KSU built in (extract ikconfig from Image)
#  - module sig / modversions still on (as designed)
#  - vermagic from a dist module (modinfo reads .modinfo, host-side)
#  - companion images: dtbo.img, vendor_dlkm.img
set -uo pipefail
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"

echo "=== dist size / key files ==="
ls -la "$DIST" | head -20
echo "total files: $(ls -1 "$DIST" | wc -l)"

echo ""
echo "=== Image ==="
if [ -f "$DIST/Image" ]; then
    ls -l "$DIST/Image"
else
    echo "NO Image IN DIST"
fi

echo ""
echo "=== ikconfig from Image ==="
if [ -f "$DIST/Image" ] && [ -x "$KSRC/scripts/extract-ikconfig" ]; then
    if "$KSRC/scripts/extract-ikconfig" "$DIST/Image" > /tmp/ikconfig.txt 2>/tmp/ikconfig.err; then
        echo "extract-ikconfig OK"
        echo "--- KSU options ---"
        grep -E '^CONFIG_KSU' /tmp/ikconfig.txt || echo "!!! CONFIG_KSU NOT FOUND !!!"
        echo "--- related options ---"
        grep -E '^CONFIG_MODULES=|^CONFIG_MODVERSIONS=|^CONFIG_MODULE_SIG=|^CONFIG_MODULE_SIG_FORCE|^CONFIG_LOCALVERSION=' /tmp/ikconfig.txt || true
    else
        echo "extract-ikconfig FAILED:"
        cat /tmp/ikconfig.err
    fi
else
    echo "Image or extract-ikconfig missing"
fi

echo ""
echo "=== vermagic (from a dist module) ==="
if [ -f "$DIST/mac80211.ko" ]; then
    modinfo "$DIST/mac80211.ko" | grep -E '^vermagic|^name' || echo "modinfo grep found nothing"
else
    echo "mac80211.ko not in dist"
fi

echo ""
echo "=== companion images ==="
ls -l "$DIST/dtbo.img" 2>/dev/null || echo "no dtbo.img in dist"
ls -l "$DIST/vendor_dlkm.img" 2>/dev/null || echo "no vendor_dlkm.img in dist"
ls -l "$DIST/vendor_boot.img" 2>/dev/null || true

echo ""
echo "=== verify done ==="
