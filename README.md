# Pixel 8 Pro (husky) custom kernel — KernelSU-Next + Wi-Fi/heat patches

Custom kernel build for the **Google Pixel 8 Pro (husky)** targeting the
heat-related Wi-Fi/Bluetooth problems, with **KernelSU-Next built in**, for
**AICP/LineageOS-based ROMs and the stock Google ROM** (one kernel build, two
packaged `boot.img` variants).

> **Honest caveat up front:** if your Wi-Fi failure is *hardware* (the Wi-Fi
> IC's solder cracking — “works when cold”), **no kernel can fix it**. These
> patches only remove the software-side failure modes (power-save wedges under
> heat, late thermal mitigation). See `docs/FLASHING.md` §5.

> **Ready-made flash set:** images, SHA-256 checksums and the official
> KernelSU-Next manager APK are attached to the
> [v1.0.0 release](https://github.com/saltykingpeppermint/pixel8pro-husky-kernel/releases/tag/v1.0.0)
> — with test instructions for telling a software Wi-Fi drop from a hardware one.

## What's changed (3 patches)

| Patch | Effect | Where it lands |
|-------|--------|----------------|
| KernelSU-Next v3.4.0 built-in | root without an LKM | `boot.img` kernel |
| Wi-Fi power-save → `PM_OFF` while active (`PM_MAX` on suspend) | no PS-poll dropouts when hot (~100–200 mW idle cost) | `vendor_dlkm` (`bcmdhd4398.ko`) |
| Passive thermal trips −5 °C (safety trips untouched) | cooler peaks (~5 % sustained perf) | `vendor_kernel_boot` packed `dtb` (4 FDTs; `dtbo.img` carries no trips) |

Full rationale + verification details: **`docs/PATCHES.md`**.

## Layout

- `docs/PLAN.md` — decisions, incidents, build state
- `docs/PATCHES.md` — the three patches in detail
- `docs/FLASHING.md` — backups, flash commands, verification, rollback, caveats
- `scripts/` — sync, integrate, patch, build (monitor + wrapper), verify,
  package helpers (all heavy bash lives in files, never inline)
- `patches/` — regenerated patch files for re-applying after a fresh sync
- `base/` — original boot.img backups (git-ignored)

The kernel source itself is **not** in this repo — it is Google's
`android-gs-shusky-6.1-android16` (GKI `android14-6.1`) synced with
`repo`, too large for GitHub. Build:

```sh
./build_shusky.sh --jobs=5 --config=use_source_tree_aosp
```

`--config=use_source_tree_aosp` is **mandatory** — the default path downloads
Google's prebuilt GKI, which has no KernelSU and mismatched module vermagic.

## Compatibility (Android version)

**v1.0.0 targets Android 16-era ROMs** — built, flashed and verified on AICP
(Android 16) and the stock Google Android 16 factory image
(`bp31.250610.009`). **Android 17 (stable since 2026-06-16) is untested.**

Android 17 should be *close* in principle — Google's docs (updated 2026-07-13)
still list husky on `android-gs-shusky-6.1-android16` / GKI `android14-6.1`,
the same KMI generation as this build, and no `android17` shusky kernel branch
exists — but nothing here has been verified on it: the dlkms drivers are a
year behind the branch HEAD, and the boot container was packed from an
Android 16 factory boot. Don't treat v1.0.0 as an Android 17 release.

Note that **every ROM OTA slot-switches back to stock images** on the new
slot — boot, dtbo, vendor_kernel_boot (thermal trips) and both dlkms. After
updating (Android 17 or any other), re-flash the full set on the newly active
slot.

## Status

See `docs/PLAN.md` § Status. Flash images are produced by
`scripts/verify-final.sh` + `scripts/package-bootimgs.sh` after a green build.
