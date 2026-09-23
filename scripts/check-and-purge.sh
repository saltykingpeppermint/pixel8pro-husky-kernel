#!/bin/bash
# 1) health: which projects have a valid HEAD in .repo/projects (refs live there)
# 2) depth audit: which object stores were created with/without --depth
# 3) purge: delete ALL abandoned tmp pack files (pure garbage, never used by git)
set -uo pipefail
R=/home/king/kernel-shusky

echo "== project gitdirs: valid vs invalid HEAD =="
VALID=0; INVALID=""
for gd in $(find "$R/.repo/projects" -maxdepth 6 -name "*.git" -type d 2>/dev/null); do
    if git --git-dir="$gd" rev-parse --verify -q HEAD >/dev/null 2>&1; then
        VALID=$((VALID+1))
    else
        INVALID="$INVALID$gd
"
    fi
done
echo "valid HEADs: $VALID"
echo "invalid HEADs: $(printf '%s' "$INVALID" | grep -c . || true)"
printf '%s' "$INVALID" | head -40

echo
echo "== depth audit of object-store configs =="
WITH=0; WITHOUT=0; WITHOUT_LIST=""
for cfg in $(find "$R/.repo/project-objects" -maxdepth 7 -name config -type f 2>/dev/null); do
    if grep -qi "depth" "$cfg" 2>/dev/null; then
        WITH=$((WITH+1))
    else
        WITHOUT=$((WITHOUT+1))
        WITHOUT_LIST="$WITHOUT_LIST${cfg%config}
"
    fi
done
echo "stores WITH depth in config:    $WITH"
echo "stores WITHOUT depth in config: $WITHOUT"
printf '%s' "$WITHOUT_LIST" | head -30

echo
echo "== purging temp pack garbage =="
BEFORE=$(du -sb "$R/.repo" 2>/dev/null | cut -f1)
N=0
while IFS= read -r f; do
    rm -f "$f" && N=$((N+1))
done < <(find "$R/.repo" -type f \( -name "tmp_pack_*" -o -name "*.tmp" \) 2>/dev/null)
AFTER=$(du -sb "$R/.repo" 2>/dev/null | cut -f1)
FREED_GB=$(( (BEFORE - AFTER) * 100 / 1024 / 1024 / 1024 ))
echo "deleted $N temp files"
echo ".repo: $((BEFORE / 1024 / 1024 / 1024))G -> $((AFTER / 1024 / 1024 / 1024))G (freed ~$((FREED_GB / 100)).$((FREED_GB % 100))G)"

echo
echo "== host drive free after purge =="
df -h /mnt/d | tail -1
