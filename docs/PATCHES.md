# Kernel patches

Three patches, written against `android-gs-shusky-6.1-android16` (GKI `android14-6.1`).
All are already applied in the WSL tree (`~/kernel-shusky`) and committed in their
respective AOSP git projects. `scripts/apply-patches.sh` regenerates the patch files
idempotently after a fresh sync.

## Patch list

| # | Patch | Files | Lands in | Purpose |
|---|-------|-------|----------|---------|
| 0001 | `CONFIG_KSU=y` | `aosp/arch/arm64/configs/gki_defconfig` | **boot.img** (kernel) | KernelSU-Next v3.4.0 built-in root |
| 0002 | Wi-Fi power-save off | `bcm4398/dhd_linux.c`, `bcm4398/wl_cfg80211.c` | **vendor_dlkm** (`bcmdhd4398.ko`) | Stable Wi-Fi link under heat |
| 0003 | Thermal −5 °C | 4 × `zuma-{a0,b0}-{ipop,foplp}.dts` | **dtb.img** (device tree) | Cooler CPU/GPU peaks |

## Why the patches land in different images

The Pixel 8 Pro kernel build (Kleaf) splits one build across several flash targets:

- **boot.img** — the GKI kernel (`vmlinux`), built from `gki_defconfig` only.
  Device defconfig fragments (`zuma_defconfig`, `shusky_defconfig`) apply *only to
  modules*, so `gki_defconfig` is the one config that shapes the flashed kernel.
  → patch 0001 lives here.
- **vendor_dlkm** (logical partition inside `super`) — out-of-tree modules:
  `bcmdhd4398.ko` (Wi-Fi), `bluetooth.broadcom`, touch/NFC/GPS…
  → patch 0002 lives here. (`bcmdhd4398` is blocklisted from auto-load and
  explicitly `modprobe`d via `insmod_cfg/init.insmod.husky.cfg`.)
- **dtb.img / dtbo** — base SoC device tree where the thermal zones/trips are
  defined. → patch 0003 lives here.
- **vendor_boot / vendor_kernel_boot** (vendor ramdisk) — early SoC modules
  (`gs_thermal.ko` TMU driver, `exynos-acme.ko` cpufreq, battery, display…).

Flashing plan (to be finalized against the stock factory image's flash-all script):
`fastboot flash boot` is required for root (0001). 0002 and 0003 take effect when
their companion images are flashed too (`vendor_dlkm` in fastbootd, `dtbo`/`dtb`
partition — exact partition names verified in the packaging step).

## 0001 — CONFIG_KSU=y

KernelSU-Next v3.4.0 was integrated by upstream `setup.sh` (drivers Makefile +
Kconfig hooks, `aosp/drivers/kernelsu -> ../../KernelSU-Next/kernel`, bridged via
a `common/drivers` symlink because this tree keeps the GKI source at `aosp/`).
Adding `CONFIG_KSU=y` compiles it into `vmlinux` → root from a single boot.img
flash, no LKM.

Build notes:
- If the build enforces the frozen KMI symbol list, run `update_symbol_list.sh`
  or build with KMI enforcement disabled — KernelSU adds new exported symbols.

## 0002 — disable Wi-Fi power save while active

```c
// dhd_linux.c (dongle init, 2 sites)          // wl_cfg80211.c (suspend/resume path)
- uint power_mode = PM_FAST;                    u32 power_mode = suspend ? PM_MAX : PM_OFF;
+ uint power_mode = PM_OFF;                            (was: suspend ? PM_MAX : PM_FAST)
```

- `PM_OFF` = radio stays awake while associated; `PM_MAX` power save is still
  applied on suspend (screen off still saves power).
- Rationale: with power save on, a heat-stressed BCM4398 misses
  beacon/DTIM windows → AP deauthorises → the classic "Wi-Fi drops when the phone
  is hot". A permanently-awake radio has no PS state machine to wedge.
  Broadcom firmware already forces PM off while BT is active
  (`PM_FORCE_OFF` exists for exactly this), so PM_OFF is a state the chip
  handles routinely.
- Honest trade-off: +~100–200 mW idle Wi-Fi power (slightly higher always-on
  radio power, but no PS transition churn).
- **If the Wi-Fi failure is hardware (IC/solder), no software patch fixes it** —
  this only removes the software-side failure mode.

## 0003 — start CPU/GPU thermal throttling 5 °C earlier

Passive `*_control_temp` trips (the governor-driven cpufreq/GPU cooling trips)
lowered by 5 °C in all four base DTBs:

| Zone | ipop (stock → new) | foplp (stock → new) |
|------|--------------------|---------------------|
| BIG (prime) | 90 → 85 °C | 95 → 90 °C |
| MID | 90 → 85 °C | 95 → 90 °C |
| LITTLE | 95 → 90 °C | 100 → 95 °C |
| G3D (GPU) | 90 → 85 °C | 100 → 95 °C |

Deliberately untouched: safety trips (`alert1/2`, `sw_max_effort`, `dfs`, `hot`
at 93–115 °C), ISP/TPU/AUR zones, and skin/battery sensors — hard protection
behaviour is unchanged, only the normal mitigation knee moves down.

Effect: cooler sustained peaks → less heat soak into the Wi-Fi/BT antenna area
and battery; cost: ~5 % lower sustained performance in heavy loads.

## Bluetooth

No dedicated BT source patch: the BCM4398 is a Wi-Fi/BT combo chip — it benefits
from 0002 (shared radio stays in a stable mode) and 0003 (cooler package). The
BT userspace stack (`CONFIG_BT=m`) is untouched.

## Re-applying after a fresh sync

```bash
# per project, from the kernel tree root:
git -C aosp                                apply patches/0001-...patch   # -p1, run inside aosp/
git -C private/google-modules/wlan/bcm4398 apply patches/0002-...patch
git -C private/devices/google/zuma         apply patches/0003-...patch
```
or simply re-run `scripts/apply-patches.sh` (idempotent; also rebuilds the patch files).
