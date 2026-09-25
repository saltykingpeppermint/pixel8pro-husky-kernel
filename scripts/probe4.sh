#!/bin/bash
# Bounded probe: download_or_build wiring, rc files, config:shusky, layers.
KSRC=/home/king/kernel-shusky
BZ="$KSRC/out/bazel/output_user_root/5d32986b71ff314335b4a702f008fef0"
BIN="$BZ/execroot/__main__/bazel-out/k8-fastbuild/bin"

echo "=== A. common.BUILD.bazel: download_or_build / prebuilt wiring ==="
grep -n -B3 -A10 "download_or_build\|gki_prebuilts" "$KSRC/private/devices/google/common/kleaf/common.BUILD.bazel" 2>/dev/null | head -100

echo ""
echo "=== B. bazelrc files (depth<=3, excl out/.repo/aosp) ==="
find "$KSRC" -maxdepth 3 -name '*.bazelrc*' -not -path '*/out/*' -not -path '*/.repo/*' -not -path '*/aosp/*' -printf '%p\n' 2>/dev/null

echo ""
echo "=== C. config:shusky definition (bounded dirs) ==="
grep -rn "config:shusky" "$KSRC/build" "$KSRC/tools" "$KSRC/private/devices" 2>/dev/null | head -10

echo ""
echo "=== D. tools/bazel.py: bazelrc handling ==="
grep -n "bazelrc\|rcfile\|config" "$KSRC/tools/bazel.py" 2>/dev/null | head -25

echo ""
echo "=== E. bin/common: did the common layer build anything? ==="
ls "$BIN/common" 2>/dev/null | head -40 || echo "(bin/common absent)"

echo ""
echo "=== F. mac80211.ko built where? ==="
find "$BIN" -name 'mac80211.ko' -printf '%p\n' 2>/dev/null | head -5

echo "=== probe4 done ==="
