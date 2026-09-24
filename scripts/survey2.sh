#!/bin/bash
# Round 2: exact patch points — WiFi PM logic, thermal trips, KMI exports.
set -uo pipefail
R=/home/king/kernel-shusky
D=$R/private/google-modules/wlan/bcm4398

echo "== 1) WiFi: module params + PM control in dhd_linux.c =="
grep -n "module_param" "$D/dhd_linux.c" | head -25
echo "-- WLC_SET_PM / dhd pm usage --"
grep -n "WLC_SET_PM\|dhd_set_pm\|->pm =\|dhd_master_mode" "$D/dhd_linux.c" | head -20
echo "-- dhd_conf / ini power save --"
grep -rn "pm=\|PM_OFF\|PM_MAX\|set_pm" "$D/dhd_common.c" 2>/dev/null | head -10

echo
echo "== 2) WiFi: where is the dhd config/ini default (power save enable?) =="
grep -rn "DHD_PM\|power_mode\|IW_PM\|espi.*pm" "$D/dhd_pcie.c" "$D/dhd_linux.c" 2>/dev/null | head -15
echo "-- roam/aggr tunables (driver tuning candidates) --"
grep -n "roam\|aggr" "$D/wl_roam.c" 2>/dev/null | head -8

echo
echo "== 3) thermal: dts files + cpu thermal trips =="
ls "$R/private/devices/google/zuma/dts" | head -30
echo "-- files containing thermal-zones --"
grep -rln "thermal-zones" "$R/private/devices/google/zuma/dts" "$R/private/devices/google/shusky/dts" 2>/dev/null | head -10

echo
echo "== 4) GKI protected exports (KMI link blockers) =="
ls "$R/aosp/android/" 2>/dev/null | grep -i "abi\|protected" | head -10
grep -rn "abi_gki_protected_exports" "$R/build/kernel" 2>/dev/null | head -5

echo
echo "== 5) device defconfig: does shusky/zuma defconfig override KSU-relevant opts? =="
grep -n "CONFIG_KSU\|CONFIG_KSUH" "$R/private/devices/google/shusky/shusky_defconfig" "$R/private/devices/google/zuma/zuma_defconfig" 2>/dev/null || echo "(none)"

echo
echo "== 6) build entrypoint sanity =="
head -30 "$R/build_shusky.sh" 2>/dev/null
