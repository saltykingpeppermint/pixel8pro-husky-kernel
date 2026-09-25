#!/bin/bash
# Diagnose KernelSU-Next manager-vs-kernel mismatch:
# find dispatcher slot logic, uapi versions, userspace probe code, repo version.
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. KernelSU-Next repo layout ==="
ls "$K" 2>/dev/null || { echo "NO REPO at $K"; exit 1; }

echo
echo "=== 2. repo version markers (git tags/branch) ==="
git -C "$K" describe --tags 2>/dev/null
git -C "$K" log --oneline -3 2>/dev/null
grep -rn "versionName" "$K/manager/build.gradle.kts" "$K/manager/app/build.gradle.kts" 2>/dev/null | head -5

echo
echo "=== 3. dispatcher slot logic in kernel ==="
grep -rn "dispatcher installed" "$K/kernel" 2>/dev/null | head -10
grep -rn "ni_syscall" "$K/kernel" 2>/dev/null | head -15

echo
echo "=== 4. uapi version definitions (kernel) ==="
grep -rn "uapi_version\|UAPI_VERSION\|uapi: " "$K/kernel" 2>/dev/null | head -20

echo
echo "=== 5. syscall slot / probe constants (kernel) ==="
grep -rn "SYS_CALL\|sys_call_table\|slot" "$K/kernel"/*.c "$K/kernel"/*.h 2>/dev/null | head -30

echo
echo "=== 6. userspace: how ksud finds the dispatcher ==="
find "$K" -maxdepth 2 -type d | head -30
grep -rn "syscall(" "$K/userspace" 2>/dev/null | head -30

echo
echo "=== 7. uapi version in userspace ==="
grep -rn "uapi" "$K/userspace" 2>/dev/null | head -20

echo
echo "=== 8. arm64 syscall numbers: 42 and 142 ==="
A="$R/aosp/include/uapi/asm-generic/unistd.h"
grep -n "nfsservctl\|__NR_reboot" "$A" 2>/dev/null | head -10
grep -rn "__NR_reboot\|__NR_nfsservctl" "$R/aosp/arch/arm64/include/uapi/asm/unistd.h" 2>/dev/null | head -5

echo
echo "=== 9. docs in repo about manager/kernel version match ==="
grep -rn -i "same version\|version.*match\|manager.*version" "$K/README.md" "$K/docs" 2>/dev/null | head -15

echo
echo "=== DONE ==="
