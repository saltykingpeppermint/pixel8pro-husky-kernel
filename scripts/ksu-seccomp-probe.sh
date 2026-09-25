#!/bin/bash
# Why did the manager's reboot-magic syscall get seccomp-killed?
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. setuid_hook.c: seccomp allow conditions (full file) ==="
cat "$K/kernel/hook/setuid_hook.c"

echo
echo "=== 2. supercall.c: reboot handler + verification ==="
sed -n '100,180p' "$K/kernel/supercall/supercall.c"

echo
echo "=== 3. who calls ksu_seccomp_allow / seccomp_allow_cache ==="
grep -rn "seccomp_allow" "$K/kernel" | head -20

echo
echo "=== 4. manager search result strings ==="
grep -rn "Searching manager\|manager found\|found manager\|packages.list detected" "$K/kernel" | head -10

echo
echo "=== 5. manager applicationId ==="
grep -rn "applicationId" "$K/manager/app/build.gradle.kts" "$K/manager/build.gradle.kts" 2>/dev/null

echo
echo "=== 6. whole repo: dispatcher slot from userspace side ==="
grep -rn "dispatcher\|ni_slot\|syscall(42\|SYS_nfsservctl" "$K/userspace" "$K/manager/app/src/main/cpp" "$K/uapi" 2>/dev/null | head -20

echo
echo "=== 7. uapi version history (KERNEL_SU_UAPI_VERSION) ==="
grep -rn "KERNEL_SU_UAPI_VERSION" "$K/uapi" "$K/kernel" 2>/dev/null | head -10

echo
echo "=== DONE ==="
