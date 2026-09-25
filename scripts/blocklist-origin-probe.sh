#!/bin/bash
set -u
R=/home/king/kernel-shusky
P="/mnt/c/Users/King/Documents/Default Project"

echo "=== 1. blocklist file content (shusky + zuma + built dist) ==="
echo "-- source shusky:"; cat "$R/private/devices/google/shusky/vendor_dlkm.blocklist.shusky"
echo "-- source zuma:"; cat "$R/private/devices/google/zuma/vendor_dlkm.blocklist.zuma" 2>/dev/null | head -20
echo "-- built dist:"; cat "$R/out/shusky/dist/vendor_dlkm.modules.blocklist" 2>/dev/null

echo
echo "=== 2. git status/blame: is blocklist upstream Google or local? ==="
git -C "$R/private/devices/google/shusky" status --short vendor_dlkm.blocklist.shusky 2>/dev/null
git -C "$R/private/devices/google/shusky" log --oneline -3 -- vendor_dlkm.blocklist.shusky 2>/dev/null
git -C "$R/private/devices/google/shusky" log --format="%h %an %ad %s" -1 2>/dev/null

echo
echo "=== 3. previous kernel (blu-spark) dmesg: did dhd/PCIe ever come up? ==="
grep -iE "No Broadcom PCI|Link is not up|dhd_bus_register|_dhd_module_init" "$P" 2>/dev/null | head -5
for f in /data/adb/ksu/log/dmesg.log /data/adb/ksu/log/dmesg.old.log; do :; done
# logs live on device; pull copies if we have them locally:
ls -la "$P/out/dmesg"* 2>/dev/null

echo
echo "=== 4. git: who last touched the blocklist (in aosp superproject?) ==="
git -C "$R" status --short private/devices/google/shusky/vendor_dlkm.blocklist.shusky 2>/dev/null | head -3

echo
echo "=== DONE ==="
