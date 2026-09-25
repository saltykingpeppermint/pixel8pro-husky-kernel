#!/bin/bash
# 1) How far behind upstream is our aosp sync?  2) shusky dist rule outputs.
# 3) Stock vendor_boot / vendor_kernel_boot contents (.kos? vermagic?).
KSRC=/home/king/kernel-shusky
FACT="/mnt/d/pixel8pro-factory/out/husky_beta-bp31.250610.009"
MK="$KSRC/tools/mkbootimg"

echo "=== fetch upstream aosp branch ==="
git -C "$KSRC/aosp" fetch aosp android-gs-shusky-6.1-android16 2>&1 | tail -5
echo "--- commits we are BEHIND upstream ---"
git -C "$KSRC/aosp" rev-list --count HEAD..aosp/android-gs-shusky-6.1-android16 2>/dev/null
echo "--- commits we have on top (our patches) ---"
git -C "$KSRC/aosp" rev-list --count aosp/android-gs-shusky-6.1-android16..HEAD 2>/dev/null
echo "--- upstream tip ---"
git -C "$KSRC/aosp" log -1 --format='%h %ci %s' aosp/android-gs-shusky-6.1-android16 2>/dev/null
echo "--- upstream Makefile version ---"
git -C "$KSRC/aosp" show aosp/android-gs-shusky-6.1-android16:Makefile 2>/dev/null | head -5

echo
echo "=== shusky BUILD lines 140-260 (dist rule) ==="
sed -n '140,260p' "$KSRC/private/devices/google/shusky/BUILD.bazel"

echo
echo "=== STOCK vendor_boot unpack ==="
rm -rf /tmp/vb; mkdir -p /tmp/vb
if [ -f "$FACT/vendor_boot.img" ]; then
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_boot.img" --out /tmp/vb >/dev/null 2>&1 || echo "unpack failed"
    ls /tmp/vb
    echo "ko count: $(find /tmp/vb -name '*.ko' | wc -l)"
    find /tmp/vb -name '*.ko' -printf '%f\n' | head -25
    FK=$(find /tmp/vb -name '*.ko' | head -1)
    if [ -n "$FK" ]; then modinfo "$FK" 2>/dev/null | grep '^vermagic'; fi
else
    echo "vendor_boot.img not extracted yet"
fi

echo
echo "=== STOCK vendor_kernel_boot unpack ==="
rm -rf /tmp/vkb; mkdir -p /tmp/vkb
if [ -f "$FACT/vendor_kernel_boot.img" ]; then
    python3 "$MK/unpack_bootimg.py" --boot_img "$FACT/vendor_kernel_boot.img" --out /tmp/vkb >/dev/null 2>&1 || echo "unpack failed"
    ls /tmp/vkb
    echo "ko count: $(find /tmp/vkb -name '*.ko' | wc -l)"
    find /tmp/vkb -name '*.ko' -printf '%f\n' | head -30
    FK=$(find /tmp/vkb -name '*.ko' | head -1)
    if [ -n "$FK" ]; then modinfo "$FK" 2>/dev/null | grep '^vermagic'; fi
else
    echo "vendor_kernel_boot.img not extracted yet"
fi

echo "=== probe10 done ==="
