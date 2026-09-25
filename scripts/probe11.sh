#!/bin/bash
# Decisive flash-set question: do the vendor ramdisks carry .ko files?
# (stock: vendor_boot + vendor_kernel_boot; ours: dist vendor_kernel_boot)
# + fips140 load-list membership + lz4 availability for packaging.
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"
FACT="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009"
MK="$KSRC/tools/mkbootimg"
LIST="/mnt/c/Users/King/Documents/Default Project/scripts/listcpio.py"

echo "=== init.insmod.husky.cfg ==="
cat "$DIST/init.insmod.husky.cfg" 2>/dev/null || echo "(absent)"

echo
echo "=== fips140 in any load list? ==="
grep -Hn "fips" "$DIST"/modules.load "$DIST"/system_dlkm.modules.load "$DIST"/vendor_dlkm.modules.load "$DIST"/vendor_kernel_boot.modules.load 2>/dev/null || echo "(not referenced by any load list)"
echo "--- load list line counts ---"
wc -l "$DIST"/*.load 2>/dev/null

echo
echo "=== lz4 / cpio tooling ==="
command -v lz4 || echo "NO lz4 on PATH"
command -v cpio || echo "NO cpio on PATH"

echo
echo "=== OUR dist vendor_kernel_boot.img ramdisks ==="
rm -rf /tmp/ovkb; mkdir -p /tmp/ovkb
python3 "$MK/unpack_bootimg.py" --boot_img "$DIST/vendor_kernel_boot.img" --out /tmp/ovkb >/dev/null 2>&1 || echo "unpack failed"
ls /tmp/ovkb
for rd in /tmp/ovkb/vendor_ramdisk* /tmp/ovkb/ramdisk*; do
    [ -f "$rd" ] || continue
    echo "--- $(basename "$rd") ---"
    python3 "$LIST" "$rd" 2>/dev/null | grep '\.ko' | sed 's/^ *[0-9]*  //' | head -30
    echo "ko count: $(python3 "$LIST" "$rd" 2>/dev/null | grep -c '\.ko')"
done

echo
echo "=== STOCK vendor_boot ramdisks ==="
rm -rf /tmp/vb; mkdir -p /tmp/vb
if [ -f "$FACT/vendor_boot.img" ]; then
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_boot.img" --out /tmp/vb >/dev/null 2>&1 || echo "unpack failed"
    for rd in /tmp/vb/vendor_ramdisk* /tmp/vb/ramdisk*; do
        [ -f "$rd" ] || continue
        echo "--- $(basename "$rd") ---"
        python3 "$LIST" "$rd" 2>/dev/null | grep '\.ko' | sed 's/^ *[0-9]*  //' | head -30
        echo "ko count: $(python3 "$LIST" "$rd" 2>/dev/null | grep -c '\.ko')"
    done
else
    echo "stock vendor_boot.img missing"
fi

echo
echo "=== STOCK vendor_kernel_boot ramdisks ==="
rm -rf /tmp/vkb; mkdir -p /tmp/vkb
if [ -f "$FACT/vendor_kernel_boot.img" ]; then
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_kernel_boot.img" --out /tmp/vkb >/dev/null 2>&1 || echo "unpack failed"
    ls /tmp/vkb
    for rd in /tmp/vkb/vendor_ramdisk* /tmp/vkb/ramdisk*; do
        [ -f "$rd" ] || continue
        echo "--- $(basename "$rd") ---"
        python3 "$LIST" "$rd" 2>/dev/null | grep '\.ko' | sed 's/^ *[0-9]*  //' | head -30
        echo "ko count: $(python3 "$LIST" "$rd" 2>/dev/null | grep -c '\.ko')"
    done
else
    echo "stock vendor_kernel_boot.img missing"
fi

echo "=== probe11 done ==="
