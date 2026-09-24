#!/bin/bash
# Round 8: locate modules list files, TMU driver, base kernel_images outputs.
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) zuma BUILD.bazel: filegroups for modules lists =="
grep -n -A3 "name = \"vendor_ramdisk_modules_list\"\|name = \"vendor_dlkm_modules_list\"\|name = \"system_dlkm_modules_list\"" "$R/private/devices/google/zuma/BUILD.bazel"

echo
echo "== 2) list-like files in zuma/ and shusky/ =="
ls "$R/private/devices/google/zuma/" | head -40
echo "-- shusky --"
ls "$R/private/devices/google/shusky/"

echo
echo "== 3) grep wlan/bluetooth in those list files =="
for f in $(find "$R/private/devices/google/zuma" "$R/private/devices/google/shusky" -type f ! -name "*.bzl" ! -name "*.bazel" ! -name "*.dts*" ! -name "Makefile" 2>/dev/null | grep -iv "OWNERS"); do
    if grep -lq "bcmdhd\|4398\|bluetooth" "$f" 2>/dev/null; then
        echo "--- $f ---"
        grep -n "bcmdhd\|4398\|bluetooth\|wlan" "$f" | head -6
    fi
done

echo
echo "== 4) TMU / thermal driver location =="
find "$R/aosp/drivers/thermal" -maxdepth 2 -type d
grep -rln "google,tmu\|gs_tmu\|tmuctrl" "$R/aosp/drivers/thermal" "$R/private/google-modules/soc/gs" 2>/dev/null | head -10

echo
echo "== 5) soc/gs: thermal module? =="
ls "$R/private/google-modules/soc/gs" | grep -i "therm\|tmu\|mitig" | head -10

echo
echo "== 6) aosp/BUILD.bazel kernel_images (560-600) =="
sed -n '560,600p' "$R/aosp/BUILD.bazel"
echo
echo "== 7) aosp/BUILD.bazel kernel_images (700,740) =="
sed -n '700,740p' "$R/aosp/BUILD.bazel"
