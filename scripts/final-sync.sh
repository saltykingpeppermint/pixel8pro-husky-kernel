#!/bin/bash
# FINAL sync attempt — foreground, fully logged.
# 1) purge leftover tmp garbage
# 2) manual --depth=1 fetch of clang via its configured remote "aosp"
#    (targeted single branch when possible; all-heads fallback for SHA pins)
# 3) repo sync (completes clang checkout + all workdirs)
# 4) verification report
set -uo pipefail
R=/home/king/kernel-shusky
M=$R/.repo/manifests/default.xml
GD=$R/.repo/projects/prebuilts/clang/host/linux-x86.git

echo "== 1) purge tmp garbage =="
find "$R/.repo" -type f -name "tmp_pack_*" -delete 2>/dev/null
echo ".repo now: $(du -sh "$R/.repo" 2>/dev/null | cut -f1)"

echo
echo "== 2) determine clang revision =="
DEFREV=$(grep -o '<default[^>]*>' "$M" | head -1 | grep -o 'revision="[^"]*"' | cut -d'"' -f2 || true)
CLINE=$(grep -o '<project[^>]*clang/host/linux-x86[^>]*>' "$M" | head -1 || true)
CLREV=$(echo "$CLINE" | grep -o 'revision="[^"]*"' | cut -d'"' -f2 || true)
REV=${CLREV:-$DEFREV}
echo "default revision: ${DEFREV:-<none>}"
echo "clang line:       ${CLINE:-<not found>}"
echo "effective rev:    ${REV:-<none>}"
if [ -z "$REV" ]; then echo "ABORT: no revision found"; exit 10; fi

echo
echo "== 3) shallow fetch clang (remote: aosp) =="
FETCH_OK=0
case "$REV" in
    refs/heads/*)
        BR=${REV#refs/heads/}
        echo "trying single branch: $BR"
        if git --git-dir="$GD" fetch --depth=1 --no-tags aosp \
            "+refs/heads/$BR:refs/remotes/aosp/$BR"; then
            FETCH_OK=1
        fi
        ;;
    refs/tags/*)
        echo "trying single tag: $REV"
        if git --git-dir="$GD" fetch --depth=1 aosp \
            "+$REV:refs/remotes/aosp/${REV#refs/tags/}" FETCH_HEAD; then
            FETCH_OK=1
        fi
        ;;
    *)
        if echo "$REV" | grep -qE '^[0-9a-f]{40}$'; then
            echo "SHA pin detected — trying direct SHA fetch"
            if git --git-dir="$GD" fetch --depth=1 --no-tags aosp "$REV"; then
                FETCH_OK=1
            fi
        else
            echo "trying branch name: $REV"
            if git --git-dir="$GD" fetch --depth=1 --no-tags aosp \
                "+refs/heads/$REV:refs/remotes/aosp/$REV"; then
                FETCH_OK=1
            fi
        fi
        ;;
esac

if [ "$FETCH_OK" -eq 0 ]; then
    echo "targeted fetch failed — fallback: all heads shallow"
    if git --git-dir="$GD" fetch --depth=1 --no-tags aosp \
        "+refs/heads/*:refs/remotes/aosp/*"; then
        FETCH_OK=1
    fi
fi

if [ "$FETCH_OK" -eq 1 ]; then
    echo "clang gitdir: $(du -sh "$GD" 2>/dev/null | cut -f1)"
    echo "HEAD now: $(git --git-dir="$GD" rev-parse --short HEAD 2>&1 | head -1)"
    [ -f "$GD/shallow" ] && echo "shallow marker: PRESENT" || echo "shallow marker: absent"
else
    echo "FETCH FAILED completely — see errors above"
fi

echo
echo "== 4) repo sync (checkouts + remaining work) =="
cd "$R" || exit 11
repo sync -c --no-tags -j2 --no-clone-bundle
SYNC_RC=$?
echo "repo sync rc=$SYNC_RC"

echo
echo "== 5) verification =="
echo "clang HEAD:  $(git --git-dir="$GD" rev-parse --short HEAD 2>&1 | head -1)"
echo "clang workdir entries: $(ls "$R/prebuilts/clang/host/linux-x86" 2>/dev/null | wc -l)"
echo "common/: $(du -sh "$R/common" 2>/dev/null | cut -f1), entries: $(ls -A "$R/common" 2>/dev/null | wc -l)"
echo "build/:  $(du -sh "$R/build" 2>/dev/null | cut -f1)"
echo ".repo:   $(du -sh "$R/.repo" 2>/dev/null | cut -f1)"
echo "tmp garbage files left: $(find "$R/.repo" -type f -name "tmp_pack_*" 2>/dev/null | wc -l)"
df -h /mnt/d | tail -1
echo "DONE rc=$SYNC_RC"
