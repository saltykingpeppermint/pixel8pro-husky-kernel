#!/bin/bash
# Kernel build runner (executed INSIDE WSL by monitor-wsl.ps1).
# Appends durable status to out/build.log on C: so the outcome survives
# WSL restarts and opencode shell-log pruning (we lost a log to that once).
LOG="/mnt/c/Users/King/Documents/Default Project/out/build.log"
mkdir -p "$(dirname "$LOG")"

STAMP=$(date '+%Y-%m-%dT%H:%M:%S%z')
echo "=== BUILD START $STAMP ===" >> "$LOG"

if ! cd /home/king/kernel-shusky >> "$LOG" 2>&1; then
  echo "BUILD_EXIT=97 (cd to kernel tree failed) $STAMP" >> "$LOG"
  exit 97
fi

# --config=use_source_tree_aosp: build the GKI Image FROM SOURCE (our aosp
# tree with CONFIG_KSU=y + wifi/thermal patches) instead of downloading
# Google's prebuilt GKI (which has no KSU and a foreign vermagic).
./build_shusky.sh --jobs=5 --config=use_source_tree_aosp >> "$LOG" 2>&1
rc=$?

echo "BUILD_EXIT=$rc $(date '+%Y-%m-%dT%H:%M:%S%z')" >> "$LOG"
exit $rc
