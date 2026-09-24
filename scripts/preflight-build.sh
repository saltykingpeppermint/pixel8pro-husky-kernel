#!/bin/bash
# Pre-flight before the Kleaf build: RAM/swap, disk, toolchain, script sanity.
set -uo pipefail
echo "== CPU / RAM / swap =="
nproc
grep -E "MemTotal|SwapTotal" /proc/meminfo
free -h 2>/dev/null || true
echo
echo "== disk =="
df -h / /mnt/d /home 2>/dev/null
echo
echo "== toolchain =="
java -version 2>&1 | head -1
python3 --version
which gcc ld curl 2>/dev/null
echo
echo "== build entrypoints =="
R=/home/king/kernel-shusky
ls -la "$R/build_shusky.sh" "$R/tools/bazel" 2>&1
echo
echo "== tree state (should be our commits, no stray changes) =="
git -C "$R/aosp" status --porcelain | head -5
git -C "$R/aosp" log --oneline -2
echo
echo "== bazel caches present? =="
ls -d /home/king/.cache/bazel 2>/dev/null || echo "(no prior bazel cache — first build will download bazel + externals)"
