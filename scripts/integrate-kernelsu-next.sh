#!/bin/bash
# Integrate KernelSU-Next into the kernel tree (built-in root).
# Run from the kernel source root: ~/kernel-shusky
set -euo pipefail

cd "$HOME/kernel-shusky"

[ -d common/drivers ] || { echo "[ERROR] run from kernel source root"; exit 1; }

# Official KernelSU-Next setup: clones repo, symlinks drivers/kernelsu,
# hooks Makefile + Kconfig. No args = latest tagged release.
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

echo "[OK] KernelSU-Next integrated."
echo "     CONFIG_KSU must be enabled in the GKI defconfig used by the build"
echo "     (set it when the build config is located in the synced tree)."
