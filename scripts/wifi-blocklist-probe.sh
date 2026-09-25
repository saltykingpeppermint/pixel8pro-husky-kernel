#!/bin/bash
# Where does 'blocklist bcmdhd4398' come from?
set -u
R=/home/king/kernel-shusky
P="/mnt/c/Users/King/Documents/Default Project"

echo "=== 1. blocklist source files in kernel tree ==="
grep -rn "bcmdhd4398" "$R" --include="*blocklist*" 2>/dev/null | head -10
find "$R" -name "*blocklist*" -not -path "*/out/*" -not -path "*/.git/*" 2>/dev/null | head -15

echo
echo "=== 2. grep 'blocklist' near wlan in build/device configs ==="
grep -rn "bcmdhd" "$R/aosp/device" "$R/aosp/vendor" 2>/dev/null | grep -i "block" | head -10
grep -rn "blocklist" "$R/aosp/device/google/husky" "$R/aosp/device/google/zuma" 2>/dev/null | head -10

echo
echo "=== 3. how was our vendor_dlkm built? (packaging script) ==="
grep -rln "vendor_dlkm" "$P/scripts" 2>/dev/null | head -10

echo
echo "=== 4. does the blocklist file exist in build output? ==="
find "$R/aosp/out" -name "modules.blocklist" 2>/dev/null | head -5
find "$R" -name "modules.blocklist" -not -path "*/.git/*" 2>/dev/null | head -8

echo
echo "=== DONE ==="
