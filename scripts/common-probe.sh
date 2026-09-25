#!/bin/bash
# Why is the GKI Image a downloaded prebuilt instead of our source build?
KSRC=/home/king/kernel-shusky

echo "=== .bazelrc: prebuilt/download flags ==="
grep -n "prebuilt\|PREBUILT\|DOWNLOAD\|download" "$KSRC/.bazelrc" 2>/dev/null | head -30
echo "--- shusky config block in .bazelrc ---"
grep -n -A12 "config:shusky" "$KSRC/.bazelrc" 2>/dev/null | head -40

echo ""
echo "=== common/ directory contents ==="
ls -la "$KSRC/common" 2>/dev/null | head -30

echo ""
echo "=== common/BUILD.bazel: kernel_aarch64 definition ==="
grep -n -B2 -A25 "name = \"kernel_aarch64\"" "$KSRC/common/BUILD.bazel" 2>/dev/null | head -60

echo ""
echo "=== does common/ have the real kernel source? ==="
ls "$KSRC/common/init" 2>/dev/null | head -5
ls -d "$KSRC/common/arch" "$KSRC/common/drivers" 2>/dev/null

echo ""
echo "=== aosp/ = GKI source? git state + KSU hooks + defconfig location ==="
if [ -d "$KSRC/aosp/.git" ]; then
    cd "$KSRC/aosp" || exit 1
    git log --format='%h %ci %s' -3
    echo "--- status (first 25) ---"
    git status --porcelain | head -25
    echo "--- KSU hooks ---"
    grep -n "kernelsu" drivers/Makefile drivers/Kconfig 2>/dev/null | head
    echo "--- CONFIG_KSU in defconfigs ---"
    grep -rn "^CONFIG_KSU" arch/arm64/configs/ kernel/configs/ 2>/dev/null | head
else
    echo "aosp/.git not found"
fi

echo "=== probe done ==="
