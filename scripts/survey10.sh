#!/bin/bash
# Round 10: exact contexts to author the patches (thermal zones, dhd PM, ramdisk list, BT knobs).
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) FULL thermal-zones in zuma-b0-ipop.dts =="
F="$R/private/devices/google/zuma/dts/zuma-b0-ipop.dts"
L=$(grep -n "thermal_zones: thermal-zones" "$F" | head -1 | cut -d: -f1)
E=$(awk -v s="$L" 'NR>s && /^	};/ {print NR; exit}' "$F")
echo "(section lines $L..$E)"
sed -n "${L},${E}p" "$F"

echo
echo "== 2) dhd_linux.c power_mode contexts =="
D=$R/private/google-modules/wlan/bcm4398
echo "-- 11470,11500 --"
sed -n '11470,11500p' "$D/dhd_linux.c"
echo "-- 12395,12425 --"
sed -n '12395,12425p' "$D/dhd_linux.c"
echo "-- wl_cfg80211.c 10245,10265 --"
sed -n '10245,10265p' "$D/wl_cfg80211.c"

echo
echo "== 3) vendor_ramdisk.modules.zuma =="
cat "$R/private/devices/google/zuma/vendor_ramdisk.modules.zuma"

echo
echo "== 4) vendor_ramdisk.modules.shusky =="
cat "$R/private/devices/google/shusky/vendor_ramdisk.modules.shusky"

echo
echo "== 5) BT broadcom module: file list =="
ls "$R/private/google-modules/bluetooth/broadcom" | head -20
