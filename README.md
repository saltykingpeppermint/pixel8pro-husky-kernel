# Pixel 8 Pro (husky) custom kernel — KernelSU-Next + Wi-Fi/heat patches

Custom kernel build for the **Google Pixel 8 Pro (husky)** targeting the
heat-related Wi-Fi/Bluetooth problems, with **KernelSU-Next built in**, for
**AICP/LineageOS-based ROMs and the stock Google ROM** (one kernel build, two
packaged `boot.img` variants).

> **Honest caveat up front:** if your Wi-Fi failure is *hardware* (the Wi-Fi
> IC's solder cracking — “works when cold”), **no kernel can fix it**. These
> patches only remove the software-side failure modes (power-save wedges under
> heat, late thermal mitigation). See `docs/FLASHING.md` §5.

## What's changed (3 patches)

| Patch | Effect | Where it lands |
|-------|--------|----------------|
| KernelSU-Next v3.4.0 built-in | root without an LKM | `boot.img` kernel |
| Wi-Fi power-save → `PM_OFF` while active (`PM_MAX` on suspend) | no PS-poll dropouts when hot (~100–200 mW idle cost) | `vendor_dlkm` (`bcmdhd4398.ko`) |
| Passive thermal trips −5 °C (safety trips untouched) | cooler peaks (~5 % sustained perf) | `dtbo.img` + `vendor_kernel_boot` DTBs |

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

## Status

See `docs/PLAN.md` § Status. Flash images are produced by
`scripts/verify-final.sh` + `scripts/package-bootimgs.sh` after a green build.
