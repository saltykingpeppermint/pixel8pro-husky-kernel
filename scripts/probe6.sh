#!/bin/bash
# Find the download-vs-build switch for the GKI Image + inspect build_shusky.sh
KSRC=/home/king/kernel-shusky
PROJ="/mnt/c/Users/King/Documents/Default Project"

echo "=== build_shusky.sh candidates ==="
for f in "$KSRC/build_shusky.sh" "$PROJ/build_shusky.sh"; do
    if [ -f "$f" ]; then
        echo "--- $f ---"
        sed -n '1,60p' "$f"
    fi
done

echo
echo "=== rc files present ==="
ls -la "$KSRC"/device.bazelrc "$KSRC"/.[cd]*.bazelrc 2>/dev/null

echo
echo "=== rc: prebuilt / download / action_env / config:shusky ==="
grep -Hn "use_prebuilt\|DOWNLOAD_BUILD\|prebuilt_gki\|action_env\|config:shusky" "$KSRC"/device.bazelrc "$KSRC"/.[cd]*.bazelrc 2>/dev/null | head -40

echo
echo "=== common_kernels.bzl: download_or_build switch ==="
grep -n "download_or_build\|use_prebuilt_gki\|KLEAF_DOWNLOAD\|gki_prebuilts" "$KSRC/build/kernel/kleaf/common_kernels.bzl" | head -40

echo
echo "=== use_prebuilt_gki across kleaf ==="
grep -rn "use_prebuilt_gki" "$KSRC/build/kernel/kleaf" 2>/dev/null | head -25

echo
echo "=== download_repo.bzl decision lines ==="
grep -n "use_prebuilt_gki\|KLEAF_DOWNLOAD\|maybe_http\|_download_or_build" "$KSRC/build/kernel/kleaf/download_repo.bzl" 2>/dev/null | head -30

echo
echo "=== where gki_prebuilts_Image repo is created ==="
grep -rn "gki_prebuilts_Image" "$KSRC/build/kernel/kleaf"/*.bzl "$KSRC/WORKSPACE" "$KSRC/MODULE.bazel" 2>/dev/null | head -15

echo "=== probe6 done ==="
