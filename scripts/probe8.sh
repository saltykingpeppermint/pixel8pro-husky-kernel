#!/bin/bash
# Inventory current dist outputs + UTS/vermagic identity of Image vs modules.
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"

echo "=== dist NON-.ko files (size) ==="
find "$DIST" -maxdepth 1 -type f ! -name '*.ko' -printf '%f  %s\n' | sort

echo
echo "=== dist .ko count ==="
find "$DIST" -maxdepth 1 -name '*.ko' | wc -l

echo
echo "=== fips140 / gki-ish modules in dist ==="
find "$DIST" -maxdepth 1 \( -name '*fips*' -o -name 'zram*' -o -name 'virtio*' \) -printf '%f\n'

echo
echo "=== linux_banner of dist/Image (its UTS) ==="
grep -a -o -m1 'Linux version [^)]*' "$DIST/Image" | head -1

echo
echo "=== vermagic of dist modules ==="
for m in mac80211.ko bcmdhd4398.ko fips140.ko 8021q.ko; do
    if [ -f "$DIST/$m" ]; then
        echo "-- $m"
        modinfo "$DIST/$m" 2>/dev/null | grep -E '^vermagic'
    fi
done

echo
echo "=== does aosp source have fips140 (can it build from source)? ==="
find "$KSRC/aosp/drivers" -maxdepth 3 -iname '*fips*' -printf '%p\n' 2>/dev/null | head -5

echo "=== probe8 done ==="
