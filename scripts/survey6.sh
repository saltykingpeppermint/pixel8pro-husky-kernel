#!/bin/bash
# Round 6: WHERE do the patches actually land? (built-in vs module vs DTB)
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) gki_defconfig: wifi/bt/thermal config state =="
grep -n "BCMDHD\|BCM4398\|CFG80211\|WLAN\|BT_BCM\|CONFIG_BT=\|WLAN_VENDOR_BROADCOM\|KSU" \
    "$R/aosp/arch/arm64/configs/gki_defconfig"

echo
echo "== 2) shusky BUILD.bazel: kernel_modules + dist outputs =="
grep -n "kernel_modules\|bcm4398\|wlan\|bluetooth\|dtb\|modules" "$R/private/devices/google/shusky/BUILD.bazel" | head -30

echo
echo "== 3) zuma BUILD.bazel: ZUMA_DTBS (which base dts is compiled) =="
grep -n "ZUMA_DTBS\|ipop\|foplp\|zuma-b0\|zuma-a0" "$R/private/devices/google/zuma/BUILD.bazel" | head -20

echo
echo "== 4) bcm4398: module or built-in? (Makefile ccflags + BUILD.bazel) =="
grep -n "obj-\|ccflags\|kernel_module\|module_group" "$R/private/google-modules/wlan/bcm4398/Makefile" | head -10
grep -n "kernel_module\|deps\|srcs" "$R/private/google-modules/wlan/bcm4398/BUILD.bazel" | head -15

echo
echo "== 5) does the SHUSKY kernel build pull in wlan module? =="
grep -rn "bcm4398\|wlan" "$R/private/devices/google/shusky/BUILD.bazel" | head -10

echo
echo "== 6) bluetooth module in build? =="
grep -rn "bluetooth\|bcm4398bt\|bt_.*\.ko" "$R/private/devices/google/shusky/BUILD.bazel" "$R/private/devices/google/zuma/BUILD.bazel" 2>/dev/null | head -10

echo
echo "== 7) dist rule outputs (shusky) =="
sed -n '175,215p' "$R/private/devices/google/shusky/BUILD.bazel"
