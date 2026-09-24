#!/bin/bash
# Round 3: exact code context for the WiFi PM patch + remaining checks.
set -uo pipefail
R=/home/king/kernel-shusky
D=$R/private/google-modules/wlan/bcm4398

echo "== 1) dhd_master_mode definition context (640-660) =="
sed -n '640,660p' "$D/dhd_linux.c"

echo
echo "== 2) WLC_SET_PM call site A (10895,10925) =="
sed -n '10895,10925p' "$D/dhd_linux.c"

echo
echo "== 3) WLC_SET_PM call site B (13020,13045) =="
sed -n '13020,13045p' "$D/dhd_linux.c"

echo
echo "== 4) DHD_PM_CONTROL_FROM_FILE block (1055,1120) =="
sed -n '1055,1120p' "$D/dhd_linux.c"

echo
echo "== 5) zuma dts files =="
ls "$R/private/devices/google/zuma/dts" 2>/dev/null | head -40

echo
echo "== 6) ABI/protected exports files =="
ls "$R/aosp/android/" 2>/dev/null | grep -i "abi\|protected" | head -10

echo
echo "== 7) device defconfigs: CONFIG_KSU? =="
grep -n "CONFIG_KSU" "$R/private/devices/google/shusky/shusky_defconfig" \
    "$R/private/devices/google/zuma/zuma_defconfig" 2>/dev/null || echo "(none - gki_defconfig is the place)"

echo
echo "== 8) build_shusky.sh head =="
head -40 "$R/build_shusky.sh" 2>/dev/null

echo
echo "== 9) thermal-zones files (full names) =="
grep -rl "thermal-zones" "$R/private/devices/google/zuma/dts" "$R/private/devices/google/shusky/dts" 2>/dev/null
