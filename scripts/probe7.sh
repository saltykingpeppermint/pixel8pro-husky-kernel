#!/bin/bash
# Understand the use_prebuilt_gki switch + rc chain before flipping the build.
KSRC=/home/king/kernel-shusky

echo "=== device.bazelrc (common) FULL ==="
cat "$KSRC/private/devices/google/common/device.bazelrc"

echo
echo "=== shusky device.bazelrc (config:shusky) ==="
cat "$KSRC/private/devices/google/shusky/device.bazelrc"

echo
echo "=== bazel.py: how rc files are assembled ==="
grep -n "bazelrc\|import\|device.bazelrc\|workspace_rc" "$KSRC/build/kernel/kleaf/bazel.py" | head -30

echo
echo "=== common_kernels.bzl 985-1075 (select defaults) ==="
sed -n '985,1075p' "$KSRC/build/kernel/kleaf/common_kernels.bzl"

echo "=== probe7 done ==="
