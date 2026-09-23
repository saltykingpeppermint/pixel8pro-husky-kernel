#!/bin/bash
# Integrate KernelSU-Next into the gs-shusky kernel tree (built-in root).
# This tree keeps the GKI source at aosp/ (not common/ or ./), while
# KernelSU's setup.sh only recognizes common/drivers or drivers — so we
# bridge with a symlink; setup.sh's edits resolve to the real aosp files.
set -euo pipefail

cd "$HOME/kernel-shusky"

[ -d aosp/drivers ] || { echo "[ERROR] aosp/drivers not found — run sync first"; exit 1; }

# Bridge layout for setup.sh (idempotent)
if [ ! -e common/drivers ]; then
    ln -s ../aosp/drivers common/drivers
    echo "[+] symlinked common/drivers -> ../aosp/drivers"
elif [ -L common/drivers ]; then
    echo "[i] common/drivers symlink already present"
fi

# Official KernelSU-Next setup: clones repo, symlinks drivers/kernelsu,
# hooks Makefile + Kconfig. No args = latest tagged release.
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

echo
echo "== verification =="
[ -e aosp/drivers/kernelsu ] && echo "[OK] aosp/drivers/kernelsu -> $(readlink aosp/drivers/kernelsu 2>/dev/null || echo present)" || echo "[FAIL] kernelsu dir missing"
grep -q "kernelsu" aosp/drivers/Makefile && echo "[OK] drivers/Makefile hooked" || echo "[FAIL] Makefile not hooked"
grep -q "kernelsu" aosp/drivers/Kconfig && echo "[OK] drivers/Kconfig hooked" || echo "[FAIL] Kconfig not hooked"

echo
echo "[i] CONFIG_KSU must be enabled in the GKI defconfig used by the build."
