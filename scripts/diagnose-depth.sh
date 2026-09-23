#!/bin/bash
# Diagnose depth mechanism + purge the second wave of tmp garbage.
set -uo pipefail
R=/home/king/kernel-shusky
M=$R/.repo/manifests/default.xml

echo "== clone-depth attributes in manifest =="
grep -o 'clone-depth="[0-9]*"' "$M" 2>/dev/null | sort | uniq -c
echo "(empty = manifest declares no clone-depth anywhere)"

echo
echo "== lwis project line (fetched shallow on Sep 22) =="
grep -o '<project name="kernel/google-modules/lwis"[^>]*' "$M" | head -1

echo
echo "== clang project line =="
grep -o '<project name="platform/prebuilts/clang/host/linux-x86"[^>]*' "$M" | head -1

echo
echo "== clang gitdir local config =="
GD=$R/.repo/projects/prebuilts/clang/host/linux-x86.git
git --git-dir="$GD" config --list --local 2>/dev/null | head -15

echo
echo "== depth persisted anywhere in repo state? =="
grep -ril "depth" "$R/.repo/manifests.git/config" 2>/dev/null
find "$R/.repo" -maxdepth 1 -type f -exec grep -li "depth" {} \; 2>/dev/null
echo "(empty = no depth persisted at .repo top level)"

echo
echo "== purge wave-2 tmp garbage =="
BEFORE=$(du -sb "$R/.repo" 2>/dev/null | cut -f1)
N=0
while IFS= read -r f; do
    rm -f "$f" && N=$((N+1))
done < <(find "$R/.repo" -type f -name "tmp_pack_*" 2>/dev/null)
AFTER=$(du -sb "$R/.repo" 2>/dev/null | cut -f1)
echo "deleted $N files; .repo $((BEFORE / 1024 / 1024 / 1024))G -> $((AFTER / 1024 / 1024 / 1024))G"

echo
df -h /mnt/d | tail -1
