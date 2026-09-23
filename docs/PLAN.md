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
- LineageOS/AICP do NOT build their own kernel for husky — they boot Google's
  GKI prebuilt → **one kernel Image serves both ROMs**; only the boot.img
  container differs → two packaged outputs, one build.
- KernelSU-Next integrates via `kernel/setup.sh`; detects `common/drivers`
  layout (present in this manifest). Requires `CONFIG_KSU` in build config.
- Packaging: Linux magiskboot builds were retired by upstream → use AOSP
  `tools/mkbootimg/{unpack_bootimg,mkbootimg}.py` from the synced tree.
- Pixel kernels in boot.img are **lz4 legacy** compressed → `lz4 -l`.
- Flash: `fastboot flash boot …` (bootloader unlocked). Back up original
  boot.img first; wrong KMI/SPL can bootloop (KMI here: `6.1-android14`).

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

## Resume checklist
- [ ] `scripts/sync-source.sh` (shallow sync)
- [ ] `scripts/integrate-kernelsu-next.sh`
- [ ] Inspect tree → write `patches/` (Wi-Fi PS off, thermal, crash handling)
- [ ] Enable `CONFIG_KSU`, build with `BUILD_AOSP_KERNEL=1 ./build_husky.sh`
- [ ] Drop `base/stock-boot.img` (Google factory image) and `base/aicp-boot.img`
      (AICP zip) → `scripts/package-bootimgs.sh`
- [ ] Flash both variants, test Wi-Fi/BT under heat load
