#!/bin/bash
# Why doesn't the kernel recognize the manager app uid? (throne_tracker/manager_identity)
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. throne_tracker: success/fail log lines around manager search ==="
grep -n "pr_info\|pr_err\|pr_warn" "$K/kernel/manager/throne_tracker.c" | sed -n '1,60p'

echo
echo "=== 2. throne_tracker: search logic (around line 345) ==="
sed -n '300,400p' "$K/kernel/manager/throne_tracker.c"

echo
echo "=== 3. manager_identity: is_uid_manager + appid defaults ==="
sed -n '1,120p' "$K/kernel/manager/manager_identity.c" 2>/dev/null || find "$K/kernel" -name "manager_identity*"

echo
echo "=== DONE ==="
