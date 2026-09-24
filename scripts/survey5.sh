#!/bin/bash
# Round 5: thermal tables/trips, mitigation module, DHD flags, built dts.
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) shusky thermal dtsi (content) =="
sed -n '1,80p' "$R/private/devices/google/shusky/dts/zuma-shusky-thermal.dtsi"

echo
echo "== 2) ripcurrent thermal dtsi trips =="
grep -n "trip\|sustainable\|temp" "$R/private/devices/google/zuma/dts/zuma-ripcurrent-thermal.dtsi" | head -30

echo
echo "== 3) thermal-zones excerpt from zuma-b0-ipop.dts =="
F="$R/private/devices/google/zuma/dts/zuma-b0-ipop.dts"
L=$(grep -n "thermal-zones" "$F" | head -1 | cut -d: -f1)
echo "(line $L)"
sed -n "${L},$((L+70))p" "$F"

echo
echo "== 4) mitigation module (power/mitigation) =="
find "$R/private/google-modules/power/mitigation" -maxdepth 2 -type f | head -30
echo "-- thermal-related tables --"
grep -rln "thermal\|trip\|mitigation_table" "$R/private/google-modules/power/mitigation" --include="*.c" --include="*.h" 2>/dev/null | head -10

echo
echo "== 5) DHD_PM_CONTROL_FROM_FILE / PM flags defined where =="
grep -rn "DHD_PM_CONTROL_FROM_FILE" "$R/private/google-modules/wlan/bcm4398/Makefile" "$R/private/google-modules/wlan/bcm4398/Kconfig" 2>/dev/null
grep -rn "DHD_PM_CONTROL_FROM_FILE\|DHD_PM_OVERRIDE" "$R/private/google-modules/wlan/bcm4398/dhd_config.h" 2>/dev/null | head -5
find "$R/private/google-modules/wlan/bcm4398" -name "Makefile*" -o -name "*.bzl" -o -name "BUILD*" | head -5

echo
echo "== 6) which husky dts is built (prod) =="
grep -rn "husky-mp\|husky_evt1_1\|dts" "$R/private/devices/google/shusky/dts/Makefile" | head -20

echo
echo "== 7) wlan dtsi (board-wlan) =="
grep -n "power\|thermal\|dfs\|regulatory" "$R/private/devices/google/zuma/dts/zuma-board-wlan.dtsi" | head -15
