#!/bin/bash
# Provenance round 2: where does the Image come from, and did the KSU patch
# reach the config that BUILDS it?
KSRC=/home/king/kernel-shusky
BZ="$KSRC/out/bazel/output_user_root/5d32986b71ff314335b4a702f008fef0"

echo "=== gki_prebuilts_Image WORKSPACE marker ==="
cat "$BZ/external/gki_prebuilts_Image/WORKSPACE.bazel" 2>/dev/null
echo ""

echo "=== references to gki_prebuilts across source (excl out/.repo) ==="
grep -rn --include='*.bzl' --include='BUILD.bazel' --include='*.bazel' --include='WORKSPACE*' --include='.bazelrc' --include='*.rc' "gki_prebuilts" "$KSRC" 2>/dev/null | grep -v "/out/" | grep -v "/.repo/" | head -30
echo "(grep done)"

echo ""
echo "=== kernel/configs git log (gki_defconfig patch commit) ==="
cd "$KSRC/kernel/configs" 2>/dev/null && git log --format='%h %ci %s' -5 || echo "kernel/configs git failed"

echo ""
echo "=== common/ kernel repo status (KSU integration commits? dirt?) ==="
if [ -d "$KSRC/common/.git" ]; then
    cd "$KSRC/common" || exit 1
    git log --format='%h %ci %s' -5
    echo "--- git status (first 25 lines) ---"
    git status --porcelain | head -25
    echo "--- KSU hooks in kernel source ---"
    grep -rn "kernelsu\|KernelSU\|KSU" init/Kconfig Makefile 2>/dev/null | head -10
    ls -d ../KernelSU-Next/kernel 2>/dev/null || true
else
    echo "common/.git NOT found"
fi

echo ""
echo "=== shusky BUILD.bazel: kernel_build + kernel_images (lines 60-215) ==="
sed -n '60,215p' "$KSRC/private/devices/google/shusky/BUILD.bazel"

echo "=== provenance2 done ==="
