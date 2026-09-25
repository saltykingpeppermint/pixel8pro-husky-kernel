#!/bin/bash
# What exactly got baked into OUR kernel, and which app id does KSU-Next want?
set -u
P="/mnt/c/Users/King/Documents/Default Project"
R=/home/king/kernel-shusky
K="$R/KernelSU-Next"

echo "=== 1. build.log: any Kbuild \$(info) lines at all? ==="
grep -c "KernelSU-Next" "$P/out/build.log" 2>/dev/null
grep -n "KernelSU-Next Manager" "$P/out/build.log" 2>/dev/null | head -6
grep -n "KernelSU-Next tag\|DCACHE flush" "$P/out/build.log" 2>/dev/null | head -6

echo
echo "=== 2. is the baked hash present in the BUILT kernel? (Image strings) ==="
IMG=$(ls "$R"/out/shusky/dist/Image "$R"/out/*/dist/Image 2>/dev/null | head -1)
echo "IMG=$IMG"
if [ -n "$IMG" ]; then
    grep -c "79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7" "$IMG" 2>/dev/null
    strings "$IMG" 2>/dev/null | grep -iE "^[0-9a-f]{64}$" | sort -u | head -5
fi

echo
echo "=== 3. KSU-Next expected app id (grep repo) ==="
grep -rn "me.weishu.kernelsu\|com.rifsxd.ksunext" "$K/kernel" "$K/userspace" "$K/uapi" 2>/dev/null | grep -v "\.git/" | head -15

echo
echo "=== 4. applicationId in manager gradle ==="
grep -rn "pplicationId" "$K/manager" --include="*.kts" --include="*.gradle" 2>/dev/null | head -10
grep -rn "DEFAULT_MANAGER_PACKAGE\|default_package" "$K/userspace" 2>/dev/null | head -10

echo
echo "=== 5. repo assets/ (official manager APK?) ==="
ls -la "$K/assets" 2>/dev/null | head -20

echo
echo "=== DONE ==="
