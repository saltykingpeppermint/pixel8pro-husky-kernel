#!/bin/bash
# What cert does is_manager_apk expect, and is CONFIG_KSU_DEBUG enabled in our build?
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. apk_sign.c tail (is_manager_apk definition) ==="
sed -n '320,359p' "$K/kernel/manager/apk_sign.c"

echo
echo "=== 2. apk_sign.h (expected cert constants) ==="
cat "$K/kernel/manager/apk_sign.h" 2>/dev/null

echo
echo "=== 3. grep expected_sha256 / MANAGER cert across kernel ==="
grep -rn "expected_sha256\|MANAGER_SIGN\|expected_size\|is_manager_apk" "$K/kernel" | head -20

echo
echo "=== 4. CONFIG_KSU_DEBUG in built config ==="
for c in "$R/aosp/out" "$R/out" "$R/kernel/out"; do :; done
find "$R/aosp" -maxdepth 3 -name ".config" 2>/dev/null | head -3
grep -rn "CONFIG_KSU" $(find "$R/aosp" -maxdepth 3 -name ".config" 2>/dev/null | head -1) 2>/dev/null | head -20

echo
echo "=== DONE ==="
