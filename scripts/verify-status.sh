#!/bin/bash
# Full status check: is the finish-sync chain alive, did clang fetch land,
# is the tree checked out. Read-only.
set -uo pipefail

echo "== our processes (chain / sync / git / backoff sleep) =="
ps -eo pid,etimes,args | grep -E "sync-source|finish-sync|repo sync|git fetch|git-remote|index-pack|sleep [0-9]+" | grep -v grep | head -8
echo "(empty above = nothing of ours running)"

echo
echo "== clang gitdir =="
GD=/home/king/kernel-shusky/.repo/projects/prebuilts/clang/host/linux-x86.git
echo "HEAD: $(git --git-dir="$GD" rev-parse --short HEAD 2>&1 | head -1)"
if [ -f "$GD/shallow" ]; then
    echo "shallow marker: yes ($(wc -l < "$GD/shallow") entries)"
else
    echo "shallow marker: no"
fi
echo "gitdir size: $(du -sh "$GD" 2>/dev/null | cut -f1)"

echo
echo "== key workdirs =="
du -sh /home/king/kernel-shusky/common \
       /home/king/kernel-shusky/prebuilts \
       /home/king/kernel-shusky/build \
       /home/king/kernel-shusky/.repo 2>/dev/null

echo
echo "== clang workdir (prebuilts/clang/host/linux-x86) =="
echo "entries: $(ls /home/king/kernel-shusky/prebuilts/clang/host/linux-x86 2>/dev/null | wc -l)"

echo
echo "== host drive =="
df -h /mnt/d | tail -1
