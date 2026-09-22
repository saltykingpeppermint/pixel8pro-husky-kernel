#!/bin/bash
# Shallow-sync the Pixel 8 Pro kernel source (no git history).
# Run inside WSL (Ubuntu 24.04). Requires: repo, git, python3 (already installed).
set -euo pipefail

BRANCH="android-gs-shusky-6.1-android16"
DIR="$HOME/kernel-shusky"
# Host drive that backs the WSL vhdx (WSL lives on D: since the C: incident).
# `df` inside WSL shows the *virtual* fs and is useless for this check,
# so we measure the real drive via its drvfs mount instead.
HOST_MOUNT="/mnt/d"
MIN_FREE_GB=30

AVAIL_GB=$(df -BG --output=avail "$HOST_MOUNT" | tail -1 | tr -dc '0-9')
if [ "${AVAIL_GB:-0}" -lt "$MIN_FREE_GB" ]; then
    echo "[ERROR] Host drive ($HOST_MOUNT) has only ${AVAIL_GB}GB free."
    echo "        Need >= ${MIN_FREE_GB}GB for shallow source + build output."
    echo "        Free space on D: or move the WSL disk: wsl --manage <distro> --move <path>"
    exit 1
fi
echo "[guard] ${AVAIL_GB}GB free on host drive — OK"

mkdir -p "$DIR" && cd "$DIR"

# --depth=1 is a repo *init* option (stored in .repo), not a sync option.
# Re-running init with it is idempotent for an existing checkout.
repo init -u https://android.googlesource.com/kernel/manifest \
          -b "$BRANCH" --no-repo-verify --depth=1

# -c = current branch only, --no-tags = skip tags: both cut download size.
# googlesource.com returns HTTP 429 under high parallelism, and --fail-fast
# would abort the whole sync on the first one — so use modest parallelism
# and retry; repo sync resumes, completed projects are not re-downloaded.
for attempt in 1 2 3 4 5; do
    echo "[sync] attempt $attempt/5"
    if repo sync -c --no-tags -j4; then
        echo "[OK] Source synced at $DIR"
        exit 0
    fi
    echo "[warn] sync failed (likely HTTP 429 rate limit) — backing off 60s"
    sleep 60
done
echo "[ERROR] sync still failing after 5 attempts"
exit 1
