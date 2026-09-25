#!/bin/bash
# Why does is_manager_apk fail? Find KSU_MANAGER_PACKAGE, EXPECTED_MANAGER_HASH,
# manager applicationId, CONFIG_KSU_DEBUG, and the :root:0 / main.jar spawn.
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. KSU_MANAGER_PACKAGE definition ==="
grep -rn "KSU_MANAGER_PACKAGE" "$K" 2>/dev/null | grep -v "\.git/" | head -20

echo
echo "=== 2. EXPECTED_MANAGER_HASH / SIZE definition ==="
grep -rn "EXPECTED_MANAGER" "$K" 2>/dev/null | grep -v "\.git/" | head -20

echo
echo "=== 3. manager applicationId / namespace ==="
grep -rn "applicationId\|namespace" "$K/manager" --include="*.kts" --include="*.gradle" --include="*.properties" 2>/dev/null | head -20

echo
echo "=== 4. versionCode mapping (managerVersionName/Code) ==="
grep -rn "managerVersionName\|managerVersionCode\|versionCode" "$K/manager" --include="*.kts" --include="*.gradle" 2>/dev/null | head -20

echo
echo "=== 5. main.jar / :root: / android:process in manager ==="
grep -rn "main.jar\|:root:\|android:process" "$K/manager/app/src/main" 2>/dev/null | head -20

echo
echo "=== 6. built .config: find it ==="
for f in "$R/aosp/out/.config" "$R/aosp/out/bazel-out" ; do :; done
find "$R" -maxdepth 4 -name ".config" -path "*out*" 2>/dev/null | head -5
find "$R/aosp/out" -name "*.config" -maxdepth 6 2>/dev/null | head -10
ls "$R/aosp/out" 2>/dev/null | head -20

echo
echo "=== 7. where does setup/Makefile bake the manager cert? ==="
grep -rn "manager_sign\|MANAGER_HASH\|sha256" "$K/kernel/Makefile" "$K/kernel/setup.sh" "$K/kernel/Kconfig" "$K/scripts" 2>/dev/null | head -20

echo
echo "=== DONE ==="
