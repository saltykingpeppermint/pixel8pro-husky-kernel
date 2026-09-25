#!/bin/bash
# Fix the failed source-build: gki_defconfig's appended CONFIG_KSU=y block is
# redundant — KernelSU-Next's Kconfig has `default y`, so `savedefconfig`
# omits the line and Kleaf's "gki_defconfig must be savedefconfig-canonical"
# check fails. KSU resolves to y WITHOUT any defconfig line (default y, deps
# KPROBES && EXT4_FS). Revert the defconfig commit, then prove locally:
#   1) .config still gets CONFIG_KSU=y  (root still shipped)
#   2) savedefconfig output == gki_defconfig byte-for-byte (check will pass)
set -u
KSRC=/home/king/kernel-shusky
cd "$KSRC/aosp" || exit 1

echo "=== deps in pristine gki_defconfig (KSU default y needs both) ==="
grep -n '^CONFIG_KPROBES=y' arch/arm64/configs/gki_defconfig || echo "!! CONFIG_KPROBES not =y"
grep -n '^CONFIG_EXT4_FS=y' arch/arm64/configs/gki_defconfig || echo "!! CONFIG_EXT4_FS not =y"

echo
echo "=== revert redundant defconfig commit bf8815155c98 ==="
git status --porcelain | head -5
git revert --no-edit bf8815155c98 || { echo "REVERT FAILED"; exit 1; }
echo "new HEAD: $(git rev-parse --short HEAD)"
echo "--- tail of gki_defconfig now:"
tail -4 arch/arm64/configs/gki_defconfig

echo
echo "=== local canonical cycle (same as Kleaf's KernelConfig action) ==="
rm -rf /tmp/kcfg && mkdir -p /tmp/kcfg
make -C "$KSRC/aosp" O=/tmp/kcfg ARCH=arm64 gki_defconfig > /tmp/kcfg1.log 2>&1
echo "gki_defconfig rc=$?"
if grep -q '^CONFIG_KSU=y' /tmp/kcfg/.config; then
    echo "[ok] CONFIG_KSU=y resolves in .config (root preserved)"
else
    echo "[FAIL] KSU not =y in .config — deps missing?"
    grep -n 'KSU' /tmp/kcfg/.config || true
    exit 1
fi

make -C "$KSRC/aosp" O=/tmp/kcfg ARCH=arm64 savedefconfig > /tmp/kcfg2.log 2>&1
echo "savedefconfig rc=$?"
if diff -u arch/arm64/configs/gki_defconfig /tmp/kcfg/defconfig > /tmp/kcfg.diff; then
    echo "[ok] savedefconfig matches gki_defconfig byte-for-byte (canonical)"
else
    echo "[FAIL] still non-canonical:"
    cat /tmp/kcfg.diff
    exit 1
fi

echo
echo "=== rotate failed build.log so the monitor starts a fresh build ==="
mv -f "/mnt/c/Users/King/Documents/Default Project/out/build.log" \
      "/mnt/c/Users/King/Documents/Default Project/out/build-fail-savedefconfig.log" \
    && echo "rotated -> out/build-fail-savedefconfig.log"

echo "FIX_OK"
