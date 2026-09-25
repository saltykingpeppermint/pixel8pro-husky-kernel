#!/bin/bash
# Find the switch that chooses gki_prebuilts download vs source build.
KSRC=/home/king/kernel-shusky
CB="$KSRC/private/devices/google/common/kleaf/common.BUILD.bazel"

echo "=== A. common.BUILD.bazel lines 1-56 (load statement) ==="
sed -n '1,56p' "$CB"

echo ""
echo "=== B. where is kernel_aarch64_download_or_build DEFINED? ==="
grep -rn "kernel_aarch64_download_or_build" "$KSRC/build/kernel/kleaf" "$KSRC/private/devices/google/common/kleaf" 2>/dev/null | grep -v "^Binary" | head -15

echo ""
echo "=== C. root rc files: configs + download flags ==="
for f in "$KSRC"/device.bazelrc "$KSRC"/.c1.bazelrc "$KSRC"/.c2.bazelrc "$KSRC"/.c3.bazelrc "$KSRC"/.c4.bazelrc "$KSRC"/.d1.bazelrc "$KSRC"/.d2.bazelrc "$KSRC"/.d15.bazelrc; do
    [ -f "$f" ] || continue
    echo "--- $(basename "$f") ---"
    grep -n "config:\|prebuilt\|download\|DOWNLOAD\|rc" "$f" 2>/dev/null | head -15
done

echo ""
echo "=== D. every root rc file mentioning shusky or download ==="
grep -l "shusky" "$KSRC"/.*.bazelrc "$KSRC"/device.bazelrc 2>/dev/null
echo "--- matches ---"
grep -n "shusky\|use_prebuilt\|DOWNLOAD_BUILD_NUMBER" "$KSRC"/.*.bazelrc "$KSRC"/device.bazelrc 2>/dev/null | head -40

echo ""
echo "=== E. tools/bazel.py rc handling ==="
ls -la "$KSRC/tools/bazel.py" 2>/dev/null || echo "bazel.py ABSENT at tools/"
grep -n "bazelrc\|bazelrc_file\|append\|rc" "$KSRC/tools/bazel.py" 2>/dev/null | head -25

echo "=== probe5 done ==="
