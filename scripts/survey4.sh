#!/binbash
#!/bin/bash
# Round 4: WiFi power_mode default, thermal trips, shusky dts wiring, git projects.
set -uo pipefail
R=/home/king/kernel-shusky
D=$R/private/google-modules/wlan/bcm4398

echo "== 1) power_mode declaration + defaults in dhd =="
grep -rn "power_mode\s*=\|uint power_mode\|int power_mode" "$D"/*.c "$D"/include/*.h 2>/dev/null | grep -v "dhdpm" | head -20
echo "-- PM_* defines --"
grep -rn "#define PM_" "$D"/include 2>/dev/null | head -10

echo
echo "== 2) rest of zuma dts file list =="
ls "$R/private/devices/google/zuma/dts" | tail -n +41

echo
echo "== 3) shusky dts dir + which dts gets built =="
ls "$R/private/devices/google/shusky/dts" 2>/dev/null
grep -rn "\.dts\|dtb" "$R/private/devices/google/shusky/BUILD.bazel" 2>/dev/null | head -15

echo
echo "== 4) trip points in cpu thermal dts (first 40 hits) =="
grep -rn "trip-point" "$R/private/devices/google/zuma/dts" 2>/dev/null | head -40

echo
echo "== 5) sustainable-power / cpu thermal zone names =="
grep -rn "sustainable-power\|cpu-thermal\|type = \"cpu" "$R/private/devices/google/zuma/dts" 2>/dev/null | head -20

echo
echo "== 6) protected exports files =="
ls "$R/aosp/android/" | grep "protected" || echo "(no protected exports files)"

echo
echo "== 7) git projects for patch targets =="
for p in aosp private/devices/google/zuma private/devices/google/shusky private/google-modules/wlan/bcm4398; do
    printf "%-42s " "$p"
    git -C "$R/$p" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "NOT-A-GIT-PROJECT"
done
