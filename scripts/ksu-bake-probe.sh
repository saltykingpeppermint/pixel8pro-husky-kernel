#!/bin/bash
# What manager package+cert did OUR kernel bake in?
set -u
P="/mnt/c/Users/King/Documents/Default Project"
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. our build.log: KSU manager bake lines ==="
grep -inE "manager package|MANAGER_HASH|MANAGER_SIZE|KSU_MANAGER" "$P/out/build.log" 2>/dev/null | head -20

echo
echo "=== 2. Kbuild lines 125-165 (where vars come from) ==="
sed -n '125,165p' "$K/kernel/Kbuild"

echo
echo "=== 3. setup.sh: exports of manager vars ==="
grep -rn "KSU_MANAGER_PACKAGE\|KSU_NEXT_MANAGER" "$K/kernel/setup.sh" "$K/scripts" "$K/build.sh" 2>/dev/null | head -20

echo
echo "=== 4. manager applicationId (full defaultConfig) ==="
grep -rn -A3 "defaultConfig\|applicationId\|applicationIdSuffix" "$K/manager/app/build.gradle.kts" | head -30

echo
echo "=== 5. AndroidManifest package ==="
grep -n "package=" "$K/manager/app/src/main/AndroidManifest.xml" | head -5

echo
echo "=== 6. check_v2_signature: what happens with empty expected hash ==="
sed -n '/^bool check_v2_signature/,/^}/p' "$K/kernel/manager/apk_sign.c" | head -40

echo
echo "=== DONE ==="
