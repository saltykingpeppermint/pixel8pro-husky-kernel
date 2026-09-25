#!/bin/bash
# Why did savedefconfig drop CONFIG_KSU=y? Inspect the hook + KSU Kconfig.
KSRC=/home/king/kernel-shusky
cd "$KSRC/aosp" || exit 1

echo "=== hooks commit (what was wired where) ==="
git log --oneline -3
echo "---"
git show 392e8c74c971 --stat | head -25

echo
echo "=== hook diff (first 120 lines) ==="
git show 392e8c74c971 | sed -n '1,120p'

echo
echo "=== kernelsu Kconfig files (bounded) ==="
find . -maxdepth 4 -path '*kernelsu*' \( -name 'Kconfig*' -o -type l \) 2>/dev/null | head -10
ls -la drivers/kernelsu 2>/dev/null | head -10

echo
echo "=== sourced from where (bounded) ==="
grep -n 'kernelsu\|KernelSU' drivers/Kconfig drivers/Makefile 2>/dev/null | head -10

echo
echo "=== KSU Kconfig content ==="
KSUK=$(find . -maxdepth 4 -path '*kernelsu*' -name 'Kconfig' 2>/dev/null | head -1)
echo "file: $KSUK"
if [ -n "$KSUK" ]; then
    cat "$KSUK"
fi

echo
echo "=== gki_defconfig tail (our appended block) ==="
tail -8 arch/arm64/configs/gki_defconfig

echo
echo "=== KSU-related lines in defconfig ==="
grep -n 'KSU' arch/arm64/configs/gki_defconfig || echo "(none)"

echo "=== probe12 done ==="
