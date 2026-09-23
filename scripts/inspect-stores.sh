#!/bin/bash
# Read-only inspection of .repo object stores: find dead/incomplete fetches,
# garbage temp packs, and shallow status. No deletions — report only.
set -uo pipefail
R=/home/king/kernel-shusky

echo "== clang store =="
G=$R/.repo/project-objects/platform/prebuilts/clang/host/linux-x86.git
echo "-- dir listing --"
ls -la "$G" 2>/dev/null | head -8
echo "-- pack dir size + contents --"
du -sh "$G/objects/pack" 2>/dev/null
ls -la "$G/objects/pack" 2>/dev/null | head -15
echo "-- refs --"
git --git-dir="$G" show-ref 2>&1 | head -5
echo "-- shallow marker --"
if [ -f "$G/shallow" ]; then echo "exists, lines: $(wc -l < "$G/shallow")"; else echo missing; fi

echo
echo "== temp/partial pack files anywhere (garbage) =="
find "$R/.repo/project-objects" -maxdepth 7 \( -name "*.tmp" -o -name "tmp_pack_*" \) -printf "%s\t%p\n" 2>/dev/null | sort -rn | head -10
echo "(none listed above = no temp garbage)"

echo
echo "== object stores WITHOUT a valid HEAD (dead/incomplete fetches) =="
FOUND=0
for d in $(find "$R/.repo/project-objects" -maxdepth 7 -name "*.git" -type d 2>/dev/null); do
    if ! git --git-dir="$d" rev-parse --verify -q HEAD >/dev/null 2>&1; then
        echo "NO-HEAD: $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
        FOUND=1
    fi
done
[ "$FOUND" -eq 0 ] && echo "(all stores healthy)"

echo
echo "== object store sizes (top 12) =="
du -h -d 5 "$R/.repo/project-objects" 2>/dev/null | sort -rh | head -12

echo
echo "== shallow markers across stores =="
CNT=$(find "$R/.repo/project-objects" -maxdepth 7 -name shallow -type f 2>/dev/null | wc -l)
echo "stores with shallow file: $CNT"
