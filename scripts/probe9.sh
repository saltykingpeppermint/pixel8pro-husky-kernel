#!/bin/bash
# Factory vendor_boot contents + stock kernel UTS + newer-tag availability
# + shusky dist rule outputs.
KSRC=/home/king/kernel-shusky
FACT="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009"
MK="$KSRC/tools/mkbootimg"

echo "=== factory dir ==="
ls -la "$FACT" 2>/dev/null | head -30

echo
echo "=== unpack factory vendor_boot (if present) ==="
if [ -f "$FACT/vendor_boot.img" ]; then
    rm -rf /tmp/vb; mkdir -p /tmp/vb
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_boot.img" --out /tmp/vb >/dev/null 2>&1 || echo "unpack failed"
    ls -la /tmp/vb
    echo "--- ramdisk .ko count ---"
    find /tmp/vb -name '*.ko' | wc -l
    echo "--- first .kos ---"
    find /tmp/vb -name '*.ko' -printf '%f\n' | head -20
    FIRSTKO=$(find /tmp/vb -name '*.ko' | head -1)
    if [ -n "$FIRSTKO" ]; then
        echo "--- vermagic of $FIRSTKO ---"
        modinfo "$FIRSTKO" 2>/dev/null | grep '^vermagic'
    fi
else
    echo "no factory vendor_boot.img"
fi

echo
echo "=== unpack factory vendor_kernel_boot (if present) ==="
if [ -f "$FACT/vendor_kernel_boot.img" ]; then
    rm -rf /tmp/vkb; mkdir -p /tmp/vkb
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_kernel_boot.img" --out /tmp/vkb >/dev/null 2>&1 || echo "unpack failed"
    find /tmp/vkb -name '*.ko' -printf '%f\n' | head -30
    echo "ko count: $(find /tmp/vkb -name '*.ko' | wc -l)"
    FIRSTKO=$(find /tmp/vkb -name '*.ko' | head -1)
    if [ -n "$FIRSTKO" ]; then
        modinfo "$FIRSTKO" 2>/dev/null | grep '^vermagic'
    fi
else
    echo "no factory vendor_kernel_boot.img"
fi

echo
echo "=== stock factory boot kernel UTS (decompress + banner) ==="
if [ -f "$FACT/boot.img" ]; then
    rm -rf /tmp/sb; mkdir -p /tmp/sb
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/boot.img" --out /tmp/sb >/dev/null 2>&1
    if [ -f /tmp/sb/kernel ]; then
        lz4 -dc /tmp/sb/kernel 2>/dev/null > /tmp/sb/Image || gzip -dc /tmp/sb/kernel 2>/dev/null > /tmp/sb/Image
        grep -a -o -m1 'Linux version [^)]*' /tmp/sb/Image | head -1
    else
        echo "no kernel extracted"
        ls /tmp/sb
    fi
fi

echo
echo "=== newer refs in aosp git? ==="
git -C "$KSRC/aosp" tag -l 2>/dev/null | grep -i 'android16\|6.1.1[3-9][0-9]' | tail -15
echo "--- remote branches ---"
git -C "$KSRC/aosp" branch -r 2>/dev/null | head -15
echo "--- manifest repo: tags/branches ---"
git -C "$KSRC/.repo/manifests" tag 2>/dev/null | tail -15
git -C "$KSRC/.repo/manifests" branch -a 2>/dev/null | head -15

echo
echo "=== shusky BUILD: dist outputs ==="
grep -n "system_dlkm\|vendor_kernel_boot\|vendor_boot\|boot.img\|_dist\|dist(" "$KSRC/private/devices/google/shusky/BUILD.bazel" | head -40

echo "=== probe9 done ==="
