#!/bin/bash
# How is download_or_build decided, and how do we force a SOURCE Image build?
KSRC=/home/king/kernel-shusky
BZ="$KSRC/out/bazel/output_user_root/5d32986b71ff314335b4a702f008fef0"

echo "=== root bazelrc / bazel wrapper ==="
ls -la "$KSRC"/.bazelrc* 2>/dev/null || echo "(no root .bazelrc*)"
echo "--- tools/bazel (first 30 lines) ---"
head -30 "$KSRC/tools/bazel" 2>/dev/null

echo ""
echo "=== where is --config=shusky defined? ==="
grep -rln "config:shusky" "$KSRC" --exclude-dir=out --exclude-dir=.repo 2>/dev/null | head -10

echo ""
echo "=== download_or_build + force flags ==="
grep -rn "download_or_build" "$KSRC/build/kernel/kleaf/"*.bzl 2>/dev/null | head -20
echo "--- build number map / use_prebuilt_gki ---"
grep -rn "KLEAF_DOWNLOAD_BUILD_NUMBER_MAP\|use_prebuilt_gki\|DOWNLOAD_OR_BUILD" "$KSRC/build/kernel/kleaf/"*.bzl 2>/dev/null | head -25

echo ""
echo "=== common.BUILD.bazel download_or_build wiring ==="
grep -n -A8 "download_or_build" "$KSRC/private/devices/google/common/kleaf/common.BUILD.bazel" 2>/dev/null | head -70

echo ""
echo "=== where was mac80211.ko built? ==="
find "$KSRC/out/bazel" -name 'mac80211.ko' -printf '%p\n' 2>/dev/null | head -5

echo ""
echo "=== did the common layer build ANYTHING? (bin/common listing) ==="
ls "$BZ/execroot/__main__/bazel-out/k8-fastbuild/bin/common/" 2>/dev/null | head -30 || echo "(bin/common absent)"

echo "=== probe3 done ==="
