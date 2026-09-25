#!/bin/bash
# What does is_manager_apk check, and can we query the crowned manager uid?
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. apk_sign.c: is_manager_apk logic ==="
sed -n '1,200p' "$K/kernel/manager/apk_sign.c" 2>/dev/null || find "$K/kernel" -name "apk_sign*"

echo
echo "=== 2. rest of apk_sign.c if longer ==="
wc -l "$K/kernel/manager/apk_sign.c" 2>/dev/null
sed -n '200,320p' "$K/kernel/manager/apk_sign.c" 2>/dev/null

echo
echo "=== 3. uapi/supercall.h: command list (looking for manager-uid query) ==="
cat "$K/uapi/supercall.h"

echo
echo "=== 4. ksud debug subcommands mapping to supercall ==="
grep -rn "ManagerUid\|manager_uid\|GET_MANAGER\|Info" "$K/userspace/ksud/src" 2>/dev/null | head -20

echo
echo "=== DONE ==="
