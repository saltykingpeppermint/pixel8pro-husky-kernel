#!/bin/bash
# Round 7: module placement (vendor ramdisk vs vendor_dlkm), thermal in-kernel logic, DTB wiring.
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) shusky BUILD.bazel: modules list file refs =="
grep -n "modules_list\|modules.list\|insmod" "$R/private/devices/google/shusky/BUILD.bazel" | head -20

echo
echo "== 2) find modules list files + contents =="
find "$R/private/devices/google" -name "*modules*list*" -o -name "*.list" 2>/dev/null | head -20

echo
echo "== 3) is bcmdhd4398/bt in vendor RAMDISK or vendor_dlkm? =="
for f in $(find "$R/private/devices/google" -name "*modules*list*" 2>/dev/null); do
    echo "--- $f ---"
    grep -n "wlan\|bcmdhd\|4398\|bluetooth\|bt_" "$f" | head -8
done

echo
echo "== 4) in-kernel thermal drivers (aosp/drivers/thermal/google) =="
ls "$R/aosp/drivers/thermal/google" 2>/dev/null | head -20
echo "-- mitigation/freq logic in code? --"
grep -rln "mitigation\|freq_table\|throttle" "$R/aosp/drivers/thermal/google" 2>/dev/null | head -10

echo
echo "== 5) google TMU driver: trips in DT, actions in code? =="
grep -n "thermal_zone_device_register\|sustainable\|power_allocator\|step_wise\|governor" \
    "$R/aosp/drivers/thermal/google/google_thermal.c" 2>/dev/null | head -10
ls "$R/aosp/drivers/thermal/google"/*.c 2>/dev/null

echo
echo "== 6) constants.bzl: which DTBs built =="
grep -n "ZUMA_DTBS\|ipop\|foplp\|husky" "$R/private/devices/google/zuma/constants.bzl" | head -15

echo
echo "== 7) boot.img: kernel really in boot for husky? (kleaf boot_image outs) =="
grep -rn "vendor_kernel_boot\|boot.img" "$R/private/devices/google/common/BUILD.bazel" 2>/dev/null | head -10
grep -rn "kernel_image_name\|kernel_images" "$R/aosp/BUILD.bazel" 2>/dev/null | head -10
