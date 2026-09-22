#!/bin/bash
# Shallow-sync the Pixel 8 Pro kernel source (no git history).
# Run inside WSL (Ubuntu 24.04). Requires: repo, git, python3 (already installed).
set -euo pipefail

BRANCH="android-gs-shusky-6.1-android16"
DIR="$HOME/kernel-shusky"
MIN_FREE_GB=60

# Refuse to start if the disk hosting us is nearly full (lesson learned).
AVAIL_GB=$(df -BG --output=avail "$DIR" 2>/dev/null | tail -1 | tr -dc '0-9' || echo 0)
if [ "${AVAIL_GB:-0}" -lt $MIN_FREE_GB ]; then
    echo "[ERROR] Only ${AVAIL_GB}GB free at $DIR — need >= ${MIN_FREE_GB}GB."
    echo "        Free space or move the WSL disk: wsl --manage <distro> --move <path>"
    exit 1
fi

mkdir -p "$DIR" && cd "$DIR"

if [ ! -d .repo ]; then
    repo init -u https://android.googlesource.com/kernel/manifest \
              -b "$BRANCH" --no-repo-verify
fi

# --depth=1: skip git history, the big disk saver
repo sync -c --no-tags --depth=1 -j"$(nproc)" --fail-fast

echo "[OK] Source synced at $DIR"
