#!/bin/bash
# Final mile: reclaim purged space via TRIM, fetch the one broken project
# (clang) manually with --depth=1 so its pack is small enough to survive
# rate limits, then resume the normal retry-loop sync for checkouts.
set -uo pipefail
R=/home/king/kernel-shusky
GD=$R/.repo/projects/prebuilts/clang/host/linux-x86.git

echo "== TRIM (return purged space to host drive) =="
sudo fstrim -av 2>&1 | grep -Ev "^fstrim: /mnt" | head -5
df -h /mnt/d | tail -1

echo
echo "== clang project info =="
echo "url:      $(git --git-dir="$GD" config --get remote.origin.url)"
echo "refspec:  $(git --git-dir="$GD" config --get remote.origin.fetch)"
echo "manifest: $(grep -o '<project name="platform/prebuilts/clang/host/linux-x86"[^>]*' "$R/.repo/manifests/default.xml" | head -1)"

echo
echo "== manual shallow fetch of clang (--depth=1) =="
URL=$(git --git-dir="$GD" config --get remote.origin.url)
REFSPEC=$(git --git-dir="$GD" config --get remote.origin.fetch)
if [ -n "$URL" ] && [ -n "$REFSPEC" ]; then
    if git --git-dir="$GD" fetch --depth=1 --no-tags origin "$REFSPEC"; then
        echo "FETCH_OK: clang now at $(git --git-dir="$GD" rev-parse --short HEAD 2>/dev/null)"
        echo "shallow file lines: $(wc -l < "$GD/shallow" 2>/dev/null || echo '?')"
    else
        echo "FETCH_FAILED (manual) — repo will retry its own way below"
    fi
else
    echo "missing url/refspec in git config — cannot manual fetch"
fi

echo
echo "== resuming normal sync (retry loop) =="
exec bash "/mnt/c/Users/King/Documents/Default Project/scripts/sync-source.sh"
