# Build plan & decisions

## Confirmed answers (from device owner)
1. ROM: **AICP** (LineageOS-based, Android 16 build) + wants a stock variant too
2. Bootloader: **unlocked**
3. Kernel: latest Android 16 build → GKI **`android14-6.1`**
4. Root: **KernelSU-Next built into the kernel** (single boot.img flash)
5. Scope: full build

## Key technical facts (researched)
- Pixel 8 Pro kernel source branch: `android-gs-shusky-6.1-android16`
  (AOSP "Build Pixel kernels" table; includes GKI kernel + Pixel drivers).
- This manifest keeps the GKI kernel source at **`aosp/`** (not `common/`,
  which is a tiny BUILD-overlay stub). Device build = Kleaf
  `//private/devices/google/shusky:zuma_shusky_dist` via `./build_shusky.sh`.
- **boot.img's kernel is built from `gki_defconfig` alone** (device defconfig
  fragments apply only to modules) → `CONFIG_KSU` goes in `gki_defconfig`.
  Wi-Fi/BT modules land in **vendor_dlkm**, thermal trips in **dtb.img**
  (see `docs/PATCHES.md` for the full flash matrix).
- LineageOS/AICP do NOT build their own kernel for husky — they boot Google's
  GKI prebuilt → **one kernel Image serves both ROMs**; only the boot.img
  container differs → two packaged outputs, one build.
- KernelSU-Next integrates via `kernel/setup.sh`; detects `common/drivers`
  layout — this tree needed a `common/drivers → ../aosp/drivers` symlink bridge
  (done). Requires `CONFIG_KSU` in build config (patch 0001, applied).
- Packaging: Linux magiskboot builds were retired by upstream → use AOSP
  `tools/mkbootimg/{unpack_bootimg,mkbootimg}.py` from the synced tree.
- Pixel kernels in boot.img are **lz4 legacy** compressed → `lz4 -l`.
- Flash: `fastboot flash boot …` (bootloader unlocked). Back up original
  boot.img first; wrong KMI/SPL can bootloop (KMI here: `6.1-android14`).
  Modules use `CONFIG_MODVERSIONS=y` → keep kernel version string compatible
  if mixing ROM-provided modules (verify `vermagic` after first build).

## Wi-Fi/BT/heat honesty
- Mix of software (thermal throttling, Wi-Fi power-save, firmware crash
  handling) and hardware (Wi-Fi IC solder — "works when cold").
- Kernel can only address the software side; hardware fault is unfixable
  in software. Expectations set accordingly.

## Incidents
- **Disk exhaustion:** full (non-shallow) repo sync filled C: to 152 MB;
  WSL became unresponsive mid-sync. Mitigations applied:
  - Recycle Bin emptied (+13 GB → 9.9 GB free)
  - WSL virtual disk moved C: → D: (`wsl --manage … --move`)
  - Future syncs are **shallow** (`--depth=1`) with a free-space guard
    script (see `scripts/sync-source.sh`).
- Decision: version *project files* in git/GitHub; kernel source itself is
  re-derivable from Google's server (too big for GitHub, already mirrored
  upstream).

- **Second disk scare (D:):** partial sync data carried over from the C: era
  included **full git histories** (the first attempt ran before `--depth=1`
  was added; later `repo init --depth=1` does not strip objects already on
  disk) — `.repo` ballooned to 35 GB, WSL vhdx to 43.8 GB, D: down to 6.5 GB.
  Also: **WSL vhdx never returns space when files are deleted inside it.**
  Fixes applied (2026-09-23):
  - `wsl --manage Ubuntu-24.04 --set-sparse true` → deletions now auto-reclaim
  - user freed 71 GB on D: → 71.4 GB free, no wipe needed; sync resumed
  - GitHub mirror idea evaluated and rejected: no mirror of
    `android-gs-shusky-6.1-android16` exists, and a self-hosted mirror can't
    fit in a free GitHub account (35 GB objects, >100 MB files) nor reduce
    local disk usage — Google remains the only source.

- **WSL boot failure (2026-09-24):** two concurrent `wsl` invocations on a
  cold VM wedged the stack — every later boot died with
  `HCS_E_CONNECTION_TIMEOUT` ("no response from the virtual machine").
  Diagnosis (fresh Alpine test distro booted instantly) isolated it to
  Ubuntu-24.04's systemd path: last-boot dmesg showed
  `WaitForBootProcess: /sbin/init failed to start within 10000ms` — systemd
  crashed mid-boot at the double-launch (dirty journals), then every retry
  outran WSL's hard 10 s boot window (self-reinforcing). Fix:
  `systemd=false` in `/etc/wsl.conf` (build box doesn't need systemd).
  vhdx fs healthy (rw mount + journal replay OK; full e2fsck still pending —
  Pass1 too slow on D: drive, do it from `WslTest` when idle).
  Notes: `.wslconfig` has `networkingMode=virtioproxy` still commented out
  (NAT used during repair, proven working; NOT the cause; re-enable after
  build). Rescue distro `WslTest` (Alpine) kept for fs maintenance
  (`wsl --unregister WslTest` to remove). **Lesson: never launch concurrent
  `wsl` boots on a cold VM — serialize them.**

## Resume checklist
- [x] `scripts/sync-source.sh` / `final-sync.sh` — sync complete 2026-09-24
      (rc=0, all 82 projects, shallow clang fetch, 0 garbage)
- [x] `scripts/integrate-kernelsu-next.sh` — KernelSU-Next **v3.4.0** integrated
- [x] Inspect tree → write `patches/` — **3 patches written, verified, committed**
      (`docs/PATCHES.md`: 0001 CONFIG_KSU, 0002 Wi-Fi PM_OFF, 0003 thermal −5 °C)
- [x] Base images obtained 2026-09-24: `base/aicp-boot.img` (adb root,
      dd of boot_a slot — 64 MB, `ANDROID!` magic ✓) + factory image
      sha256-verified & extracted →
      `D:\pixel8pro-factory\out\husky_beta-bp31.250610.009\`
      (boot.img, dtbo.img, vbmeta{,_system,_vendor}.img, android-info.txt)
- [ ] Kleaf build **RUNNING** (2026-09-24, `./build_shusky.sh --jobs=5`)
      → verify vermagic vs stock; also record which dtb/dtbo/vendor_dlkm
      artifacts the dist emits
- [ ] `scripts/package-bootimgs.sh` → two boot.imgs. Factory flash list
      (fastboot-info.txt): boot, init_boot, dtbo, vendor_kernel_boot, pvmfw,
      vendor_boot, vbmeta (`--apply-vbmeta`), vbmeta_system, vbmeta_vendor,
      then super logicals incl. **vendor_dlkm** — **no dtb partition exists**
      → base DTBs ship inside `dtbo.img` → patch 0003 rides our built
      dtbo.img (confirm vs dist output)
- [ ] Flash both variants, test Wi-Fi/BT under heat load

## Status (2026-09-24)
- Source tree complete (22 GB), KernelSU-Next in, all three patches applied &
  committed in-tree (aosp `bf8815155c98`, bcm4398 `cdf02d5`, zuma `ebc7b94`).
- Patch files mirrored in project repo `patches/`.
- WSL repaired after boot-failure incident (see Incidents) — `systemd=false`.
- Both base images in hand (AICP via adb, stock factory verified+extracted).
- **Kleaf build running** (`./build_shusky.sh --jobs=5`, background).
- Next: build → verify vermagic → package both boot.imgs + companion images
  → flash instructions (with hardware-vs-software Wi-Fi caveat).
