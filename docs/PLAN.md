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

- **3× BSOD (2026-09-24, bugcheck 0x3B SYSTEM_SERVICE_EXCEPTION, same fault
  offset):** all three traced to abnormal termination of Hyper-V compute
  components (force-killing `vmcompute`/`vmwp` during repair playbooks).
  Hard rule adopted: **never kill `vmwp`/`vmmem`/`vmcompute`** — safe paths
  only (`wsl --shutdown`, `WslService` recycle, `Restart-Service vmcompute`).
  Monitor playbook rewritten around this; fsck then ran clean.

- **Prebuilt-vs-source trap (2026-09-24, the key discovery):** the default
  Kleaf path (`device.bazelrc` → `use_prebuilt_gki=true` + Kleaf download map)
  *downloads* Google's GKI — the "successful" first build produced a dist
  whose `Image` was `6.1.124-…-g8d713f9e8e7b-ab13202960` (no KernelSU,
  vermagic from a different build than our device modules, fips140.ko from a
  third identity). Full vermagic matrix recorded; conclusion: mixed dist was
  unflashable. Supported override: `--config=use_source_tree_aosp`
  (`--kernel_package=@//aosp --use_prebuilt_gki=false --use_signed_prebuilts=false`).
  All builds now go through `scripts/build-wrapper.sh`, which passes it and
  self-logs `BUILD_EXIT=<rc>` as the authoritative outcome.

- **savedefconfig-canonical failure (2026-09-24):** first source-build attempt
  died at Kleaf's `KernelConfig` action:
  `ERROR: savedefconfig does not match aosp/arch/arm64/configs/gki_defconfig`
  — the appended `CONFIG_KSU=y` block was dropped by `savedefconfig` because
  KernelSU-Next's Kconfig has `default y` (redundant entry; comments are never
  canonical either). Fix: reverted the defconfig commit (`51d090c67d6e`);
  `CONFIG_KSU=y` still resolves via the Kconfig default (deps
  `KPROBES=y`+`EXT4_FS=y` confirmed in `gki_defconfig`), and the canonical
  check now passes (build proceeded to full compile).

- **Monitor 5.1 crash (2026-09-24):** watchdog started with `powershell.exe`
  (5.1/.NET Framework) died instantly — `ProcessStartInfo.ArgumentList` only
  exists on PowerShell 7. Fixed with a version guard + always launching via
  `pwsh -NoProfile -File`.

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
- [ ] **Source build** running under `scripts/monitor-wsl.ps1` (pwsh,
      `scripts/build-wrapper.sh` → `./build_shusky.sh --jobs=5
      --config=use_source_tree_aosp`, `BUILD_EXIT=` protocol; failed attempt 1
      = savedefconfig-canonical, fixed via revert `51d090c67d6e`)
- [ ] `scripts/verify-final.sh` — Image UTS == aosp HEAD, `CONFIG_KSU=y`
      (ikconfig), module vermagics, wifi/thermal patches, KMI violations
- [ ] `scripts/package-bootimgs.sh` → two boot.imgs **+ copies companion
      images** (dtbo, system_dlkm, vendor_dlkm, vendor_kernel_boot) into
      `out/`; hard-guards against packaging a kernel without CONFIG_KSU
- [ ] Flash both variants, test Wi-Fi/BT under heat load
      (`docs/FLASHING.md` written: flash set, backups, rollback, caveats)

## Status (2026-09-24, 22:55)
- Source tree complete (22 GB), KernelSU-Next v3.4.0 in-tree, patches
  committed: aosp hooks `392e8c74c971` (defconfig entry reverted
  `51d090c67d6e` — KSU via Kconfig `default y`), bcm4398 `cdf02d5`,
  zuma `ebc7b94`.
- **Source build attempt 2 RUNNING** under the monitor (config check passed
  at ~22:56; attempt limit 3; log `out/build.log`, watchdog `out/monitor.log`).
- Docs: `docs/FLASHING.md` written; PATCHES/PLAN updated (prebuilt trap +
  canonical-defconfig incident).
- Packaging script hardened (dist-Image pin + CONFIG_KSU guard + companions).
- Pending: BUILD_OK → `verify-final.sh` → `package-bootimgs.sh` → commit+push
  scripts/docs → cleanup (`.wslconfig` virtioproxy restore, unregister
  WslTest) → delivery message (flash steps + honest caveats).
