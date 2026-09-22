# Pixel 8 Pro Custom Kernel (husky)

Custom kernel project for **Google Pixel 8 Pro (husky)** addressing Wi-Fi/Bluetooth
failures caused by heat and software, with **KernelSU-Next** root built in.

## Target

| Item | Value |
|---|---|
| Device | Google Pixel 8 Pro (`husky`), Tensor G3 |
| ROM (primary) | AICP (LineageOS-based), Android 16 build |
| ROM (secondary) | Stock Google firmware |
| Kernel source | `android-gs-shusky-6.1-android16` (GKI `android14-6.1`) |
| Root | KernelSU-Next compiled into the kernel (single `boot.img` flash) |
| Output | Two flashable `boot.img` files: stock-based + AICP-based |

## Important caveat

The widely reported Pixel 8 Pro Wi-Fi/BT failure when hot has **two causes**:

1. **Software** (what this kernel targets): thermal throttling behavior, Wi-Fi
   power-save, driver/firmware crash handling.
2. **Hardware** (not fixable in software): failed solder joints under the Wi-Fi
   IC — the "works when ice-cold" symptom. If the unit has this fault, no
   kernel will fix it.

## Status

- [x] Research: GKI/KMI, KernelSU-Next integration, packaging approach
- [x] Build environment: WSL Ubuntu 24.04 toolchain installed
- [x] Build machine relocated: WSL virtual disk moved C: → D: (disk space scare)
- [ ] Shallow `repo sync` of kernel source (interrupted — resume here)
- [ ] Integrate KernelSU-Next (`kernel/setup.sh`)
- [ ] Wi-Fi/BT/thermal patches (inspect tree first, then patch)
- [ ] Kleaf build (`BUILD_AOSP_KERNEL=1 ./build_husky.sh`)
- [ ] Package `boot.img` ×2 via AOSP `unpack_bootimg`/`mkbootimg`
- [ ] Flash & verify (unlocked bootloader)

## Resume (from a fresh WSL session)

```bash
# 1. shallow source sync (no git history = ~1/3 the disk usage)
mkdir -p ~/kernel-shusky && cd ~/kernel-shusky
repo init -u https://android.googlesource.com/kernel/manifest \
          -b android-gs-shusky-6.1-android16 --no-repo-verify
repo sync -c --no-tags --depth=1 -j8

# 2. KernelSU-Next integration
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

# 3. build (patch scripts live in patches/)
BUILD_AOSP_KERNEL=1 ./build_husky.sh
```

**Disk rule of thumb:** kernel shallow source ≈ 10–15 GB + build output ≈
10–20 GB. Keep ≥ 60 GB free on the drive hosting WSL before syncing.

## Layout

- `patches/` — Wi-Fi/BT/thermal kernel patches (created once source is inspected)
- `scripts/` — build + packaging helpers
- `out/` — final flashable images land here
