#!/bin/bash
# Map every manifest project path to its workdir population — answers
# "where does the kernel source actually live" and flags empty checkouts.
set -uo pipefail
R=/home/king/kernel-shusky
M=$R/.repo/manifests/default.xml

echo "== top-level workdir population =="
for d in "$R"/*/; do
    n=$(basename "$d")
    case "$n" in .repo) continue;; esac
    cnt=$(ls -A "$d" 2>/dev/null | wc -l)
    sz=$(du -sh "$d" 2>/dev/null | cut -f1)
    printf "%-28s %6s entries  %s\n" "$n" "$cnt" "$sz"
done

echo
echo "== manifest projects: path + populated? =="
grep -o '<project[^>]*>' "$M" | while read -r line; do
    p=$(echo "$line" | grep -o 'path="[^"]*"' | cut -d'"' -f2)
    n=$(echo "$line" | grep -o 'name="[^"]*"' | cut -d'"' -f2)
    [ -z "$p" ] && p=$n
    if [ -d "$R/$p" ]; then
        cnt=$(ls -A "$R/$p" 2>/dev/null | wc -l)
        if [ "$cnt" -eq 0 ]; then st="EMPTY!"; else st="ok($cnt)"; fi
    else
        st="MISSING-DIR"
    fi
    printf "%-60s %-22s %s\n" "$p" "$st" "$n"
done

echo
echo "== where is the Linux Makefile? (kernel source root) =="
find "$R" -maxdepth 3 -name Makefile -path "*common*" 2>/dev/null | head -5
ls "$R/common" 2>/dev/null
echo
echo "== biggest populated dirs (depth 2) =="
du -h -d 2 "$R" 2>/dev/null | sort -rh | head -15
