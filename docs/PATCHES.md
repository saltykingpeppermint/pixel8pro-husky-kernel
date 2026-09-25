# Kernel patches

Three patches, written against `android-gs-shusky-6.1-android16` (GKI `android14-6.1`).
All are already applied in the WSL tree (`~/kernel-shusky`) and committed in their
respective AOSP git projects. `scripts/apply-patches.sh` regenerates the patch files
idempotently after a fresh sync.

## Patch list

| # | Patch | Files | Lands in | Purpose |
|---|-------|-------|----------|---------|
| 0001 | KernelSU built-in | `aosp` (Kconfig/Makefile hooks) + KernelSU-Next `default y` | **boot.img** (kernel) | KernelSU-Next v3.4.0 built-in root |
| 0002 | Wi-Fi power-save off | `bcm4398/dhd_linux.c`, `bcm4398/wl_cfg80211.c` | **vendor_dlkm** (`bcmdhd4398.ko`) | Stable Wi-Fi link under heat |
| 0003 | Thermal −5 °C | 4 × `zuma-{a0,b0}-{ipop,foplp}.dts` | **dtbo.img** + **vendor_kernel_boot/dtb** (base DTBs ride both; husky has no `dtb` partition) | Cooler CPU/GPU peaks |

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
- **dtbo.img** — contains the base SoC device trees (where the thermal
  zones/trips are defined) *plus* the board overlay. husky has **no `dtb`
  partition** (verified against the factory image's `fastboot-info.txt`), so
  the built DTBs ship inside the dtbo partition image. → patch 0003 lives here.
- **vendor_boot / vendor_kernel_boot** (vendor ramdisk) — early SoC modules
  (`gs_thermal.ko` TMU driver, `exynos-acme.ko` cpufreq, battery, display…).

Flashing plan (verified against the stock factory image's `fastboot-info.txt`):
`fastboot flash boot` is required for root (0001). 0002 and 0003 take effect when
their companion images are flashed too: `fastboot flash dtbo dtbo.img` (0003) and
`fastboot flash vendor_dlkm vendor_dlkm.img` from fastbootd
(`fastboot reboot fastboot` first — vendor_dlkm is a logical partition inside
`super`). Stock flash list: boot, init_boot, dtbo, vendor_kernel_boot, pvmfw,
vendor_boot, vbmeta (`--apply-vbmeta`), vbmeta_system, vbmeta_vendor, then super
logicals (system, system_dlkm, system_ext, product, vendor, vendor_dlkm).

## 0001 — KernelSU built into the kernel

KernelSU-Next v3.4.0 was integrated by upstream `setup.sh` (drivers Makefile +
Kconfig hooks, `aosp/drivers/kernelsu -> ../../KernelSU-Next/kernel`, bridged via
a `common/drivers` symlink because this tree keeps the GKI source at `aosp/`).

**How CONFIG_KSU ends up =y — the defconfig entry was reverted (2026-09-24):**
KernelSU-Next's Kconfig declares `config KSU … default y` (tristate, deps
`KPROBES && EXT4_FS`, both =y in `gki_defconfig`). An explicit `CONFIG_KSU=y`
line in `gki_defconfig` is therefore *redundant*, and Kleaf's `KernelConfig`
action enforces that `gki_defconfig` be byte-identical to `make savedefconfig`
output — `savedefconfig` drops value==default entries, so the appended block
(comment + blank line + `CONFIG_KSU=y`) failed the build with
`ERROR: savedefconfig does not match aosp/arch/arm64/configs/gki_defconfig`.
Fix: reverted the defconfig commit (`51d090c67d6e`); KSU resolves to `=y`
purely via its Kconfig default, and the canonical check passes. Verified
locally: `make gki_defconfig` → `.config` contains `CONFIG_KSU=y`.

**Critical: this only works on the source build.** The default path downloads
Google's *prebuilt* GKI (`device.bazelrc`: `use_prebuilt_gki=true` + Kleaf
download map), which has no KernelSU and a different vermagic. The build
**must** pass `--config=use_source_tree_aosp`
(`scripts/build-wrapper.sh` does).

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

> **Note (2026-09-24):** `patches/0001-gki_defconfig-CONFIG_KSU.patch` is
> **superseded** — do NOT re-add the defconfig entry (it breaks Kleaf's
> savedefconfig-canonical check; KSU is enabled by its Kconfig `default y`).
> The still-required part of 0001 is the drivers Kconfig/Makefile hook commit
> (`392e8c74c971` in `aosp/`), regenerated as a patch by
> `scripts/apply-patches.sh`.
