#!/bin/bash
# Round 9: kernel_build wiring — where does gki_defconfig vs zuma/shusky defconfig apply?
set -uo pipefail
R=/home/king/kernel-shusky

echo "== 1) shusky BUILD.bazel: kernel_build call (lines 1-90) =="
sed -n '1,90p' "$R/private/devices/google/shusky/BUILD.bazel"

echo
echo "== 2) common/BUILD.bazel (stub) =="
cat "$R/common/BUILD.bazel"

echo
echo "== 3) build.config.zuma: defconfig merge =="
cat "$R/private/devices/google/zuma/build.config.zuma" 2>/dev/null

echo
echo "== 4) gki_defconfig: LOCALVERSION / modversions / stamp related =="
grep -n "LOCALVERSION\|MODVERSIONS\|MODULE_SIG\|CFG80211\|MAC80211" "$R/aosp/arch/arm64/configs/gki_defconfig"

echo
echo "== 5) zuma_defconfig head + built-in additions =="
head -30 "$R/private/devices/google/zuma/zuma_defconfig"
echo "..."
grep -c "=y" "$R/private/devices/google/zuma/zuma_defconfig"
grep -c "=y" "$R/private/devices/google/shusky/shusky_defconfig"
