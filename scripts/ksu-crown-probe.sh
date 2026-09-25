#!/bin/bash
# Manager crowning rules: package list, signature magic, uid validity, appid default.
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. throne_tracker.c lines 1-100 (crowning + magic check) ==="
sed -n '1,100p' "$K/kernel/manager/throne_tracker.c"

echo
echo "=== 2. throne_tracker.c lines 130-260 (apk scan + magic compare) ==="
sed -n '130,260p' "$K/kernel/manager/throne_tracker.c"

echo
echo "=== 3. manager_identity.h ==="
cat "$K/kernel/manager/manager_identity.h"

echo
echo "=== 4. manager_identity.c: appid default + validity ==="
find "$K/kernel" -name "manager_identity.c" -exec cat {} \; 2>/dev/null | head -120

echo
echo "=== 5. expected magic constant ==="
grep -rn "expected\|MAGIC" "$K/kernel/manager" "$K/kernel/include" 2>/dev/null | grep -i "magic" | head -20

echo
echo "=== 6. KSU-Next manager applicationId (whole repo) ==="
grep -rn "applicationId" "$K/manager" 2>/dev/null | grep -v Binary | head -10

echo
echo "=== DONE ==="
