#!/bin/bash
# Regenerate patches/0001-kernelsu-hooks.patch from the aosp hook commit
# (same command apply-patches.sh step 2 runs). Safe on any machine with WSL.
set -euo pipefail
R=/home/king/kernel-shusky
OUT="$(cd "$(dirname "$0")/.." && pwd)/patches"

HOOK_SHA=$(git -C "$R/aosp" log --format=%H --grep='KernelSU-Next.*hooks' -1)
[ -n "$HOOK_SHA" ] || { echo "FAIL: KernelSU hook commit not found in aosp"; exit 1; }

git -C "$R/aosp" show --no-color "$HOOK_SHA" -- drivers/Kconfig drivers/Makefile \
    > "$OUT/0001-kernelsu-hooks.patch"
test -s "$OUT/0001-kernelsu-hooks.patch" || { echo "FAIL: 0001 patch empty"; exit 1; }

echo "[ok] $OUT/0001-kernelsu-hooks.patch from $HOOK_SHA"
wc -l "$OUT/0001-kernelsu-hooks.patch"
head -12 "$OUT/0001-kernelsu-hooks.patch"
