#!/bin/bash
# Survey the Wi-Fi/BT/thermal/defconfig targets before patching.
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) GKI defconfig: path + CONFIG_KSU state =="
DC=$(find "$R/aosp/arch/arm64/configs" -name "*defconfig" 2>/dev/null | head -5)
echo "$DC"
if [ -f "$R/aosp/arch/arm64/configs/gki_defconfig" ]; then
    grep -n "CONFIG_KSU" "$R/aosp/arch/arm64/configs/gki_defconfig" || echo "(no CONFIG_KSU yet)"
    echo "defconfig lines: $(wc -l < "$R/aosp/arch/arm64/configs/gki_defconfig")"
fi

echo
echo "== 2) Wi-Fi driver: bcm4398 + bcmdhd structure =="
find "$R/private/google-modules/wlan/bcm4398" -maxdepth 2 -type d 2>/dev/null | head -20
echo "-- bcmdhd dirs --"
find "$R/private/google-modules/wlan/bcmdhd" -maxdepth 3 -type d 2>/dev/null | head -25
echo "-- key source files (bcm4398) --"
find "$R/private/google-modules/wlan/bcm4398" -maxdepth 3 -name "*.c" 2>/dev/null | head -25

echo
echo "== 3) thermal mitigation module =="
find "$R/private/google-modules/power/mitigation" -type f 2>/dev/null | head -20

echo
echo "== 4) Tensor G3 device tree files =="
ls "$R/private/devices/google/zuma" 2>/dev/null
ls "$R/private/devices/google/shusky" 2>/dev/null

echo
echo "== 5) thermal zones in zuma/shusky dts =="
grep -rln "thermal-zones\|trip-point" "$R/private/devices/google/zuma" "$R/private/devices/google/shusky" 2>/dev/null | head -10

echo
echo "== 6) bluetooth modules =="
find "$R/private/google-modules/bluetooth" -maxdepth 3 -type f -name "*.c" 2>/dev/null | head -15

echo
echo "== 7) power save / PM symbols in wifi driver (where's the switch?) =="
grep -rln "WLC_SET_PM\|dhd_set_pm\|wlc_pm\|power_save\|wl_pm" "$R/private/google-modules/wlan/bcm4398" 2>/dev/null | head -12
