#!/bin/bash
# Pin down KernelSU-Next uapi migration: how kernel 3.4.0 and userspace 3.3.0 talk.
set -u
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. uapi header: version + magic ==="
grep -n "UAPI_VERSION\|MAGIC\|dispatcher\|SLOT" "$K/uapi/ksu.h" 2>/dev/null | head -30

echo
echo "=== 2. how does userspace call the kernel (ksucalls.rs) ==="
sed -n '90,150p' "$K/userspace/ksud/src/ksucalls.rs"

echo
echo "=== 3. reboot-magic usage across userspace ==="
grep -rn "SYS_reboot\|__NR_reboot\|KSU_INSTALL_MAGIC" "$K/userspace" 2>/dev/null | head -20

echo
echo "=== 4. does kernel hook reboot at all? ==="
grep -rn "reboot" "$K/kernel" 2>/dev/null | grep -vi "pr_info\|comment" | head -20

echo
echo "=== 5. dispatcher discovery on kernel side (arm64) ==="
sed -n '200,260p' "$K/kernel/hook/arm64/syscall_hook.c"

echo
echo "=== 6. how userspace discovers dispatcher slot ==="
grep -rn "find.*slot\|ni_syscall\|dispatcher\|probe" "$K/userspace/ksud/src" 2>/dev/null | head -20

echo
echo "=== 7. manager: detection / version strings ==="
grep -rn "not detected\|uapi_mismatch\|su_compat\|getVersion" "$K/manager/app/src/main" 2>/dev/null | grep -v "res/values" | head -25

echo
echo "=== 8. manager versionName source ==="
grep -rn "managerVersionName" "$K/manager" 2>/dev/null | head -10

echo
echo "=== 9. changelog: uapi 2 -> 4 / reboot->dispatcher migration ==="
git -C "$K" log --oneline -30 2>/dev/null

echo
echo "=== DONE ==="
