# Flashing guide — custom kernel for Pixel 8 Pro (husky)

This build produces **one kernel build, two boot.img variants** plus a set of
companion images. Everything in the set comes from the *same* kernel build and
is locked together by module vermagic + symbol CRCs — **flash the whole set,
never just `boot.img`**, or Wi-Fi/Bluetooth modules will be rejected at load
time.

## What gets flashed

| File (in `out/`)               | Replaces partition       | Why |
|--------------------------------|--------------------------|-----|
| `boot-aicp.img` **or**         | `boot`                   | Kernel with KernelSU-Next built in + your ROM's original ramdisk/init (only the kernel is swapped) |
| `boot-stock.img`               | `boot` (Google stock ROM) | same, packed into the factory boot container |
| `dtbo.img`                     | `dtbo`                   | device tree incl. lowered **passive** thermal trips (safety trips untouched) |
| `vendor_kernel_boot.img`       | `vendor_kernel_boot`     | bootloader DTB source built from the same patched source |
| `system_dlkm.img`              | `system_dlkm` (logical)  | GKI modules (modversions-locked to this exact kernel) |
| `vendor_dlkm.img`              | `vendor_dlkm` (logical)  | vendor modules incl. **bcmdhd4398 Wi-Fi driver** with power-save patch |

Use `boot-aicp.img` on AICP (and other LineageOS-based ROMs), `boot-stock.img`
on the Google factory ROM.

## 0. Requirements

- Bootloader unlocked (`fastboot flashing unlock` already done on this device)
- `platform-tools` (fastboot/adb) on PATH
- The phone charged > 50 %
- **Original images backed up first** (see below) — this is your rollback path

## 1. Back up the originals (do this first)

On the AICP device adbd runs as root, so plain `dd` works:

```sh
adb root
adb shell mkdir -p /sdcard/kernel-backup
adb shell 'dd if=/dev/block/by-name/boot_a              of=/sdcard/kernel-backup/boot.img bs=4096'
adb shell 'dd if=/dev/block/by-name/dtbo_a              of=/sdcard/kernel-backup/dtbo.img bs=4096'
adb shell 'dd if=/dev/block/by-name/vendor_kernel_boot_a of=/sdcard/kernel-backup/vendor_kernel_boot.img bs=4096'
adb shell 'dd if=/dev/block/by-name/system_dlkm_a        of=/sdcard/kernel-backup/system_dlkm.img bs=4096'
adb shell 'dd if=/dev/block/by-name/vendor_dlkm_a        of=/sdcard/kernel-backup/vendor_dlkm.img bs=4096'
adb pull /sdcard/kernel-backup .
```

(If a `by-name` entry is missing, the logical partitions also exist as
`/dev/block/mapper/system_dlkm_a` etc.) Keep those five files somewhere safe
outside the phone.

Stock-ROM users: `adb root` is unavailable on user builds — your originals for
`boot`, `dtbo`, `vendor_kernel_boot` are the files in the factory zip
(`D:\pixel8pro-factory\out\husky_beta-…\`), and `system_dlkm`/`vendor_dlkm`
can be extracted from `super.img` with `simg2img` + `lpunpack` if you want a
byte-exact backup.

## 2. Flash

```sh
adb reboot bootloader

# bootloader-mode partitions
fastboot flash boot out/boot-aicp.img          # or boot-stock.img
fastboot flash dtbo out/dtbo.img
fastboot flash vendor_kernel_boot out/vendor_kernel_boot.img

# logical partitions are flashed in fastbootd
fastboot reboot fastboot
fastboot flash system_dlkm out/system_dlkm.img
fastboot flash vendor_dlkm out/vendor_dlkm.img

fastboot reboot
```

Notes:

- fastboot flashes **the current slot only**. Check with
  `adb shell getprop ro.boot.slot_suffix`. After a ROM OTA (which switches to
  the other slot) the custom kernel is gone from the newly active slot — just
  repeat steps 2 on the new slot.
- An unlocked bootloader showing the orange “verified boot” warning is normal.
- If the bootloader rejects boot/vbmeta (bootloop instead of booting):
  `fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img`
  with the `vbmeta.img` from your backup/factory images.

## 3. First boot — verify

```sh
# kernel identity: must show our commit hash (git describe of aosp HEAD),
# NOT 6.1.124-android14-11-g8d713f9e8e7b (Google's prebuilt)
adb shell cat /proc/version

# module load health: must be empty (no vermagic/CRC rejections)
adb shell dmesg | grep -iE 'vermagic|disagrees|module.*not found'

# lowered passive trips present (millicegrees: 90000/95000 foplp, 85000/90000 ipop)
adb shell 'grep -h . /sys/class/thermal/thermal_zone*/trip_point_*_temp | sort -u | head -40'
```

**KernelSU-Next**: install the KernelSU-Next **manager APK** (same version as
the integrated source, v3.4.0, from their GitHub releases). It should detect
the built-in kernel and report its version. Grant yourself root there, then
test: `adb shell su -c id`.

Wi-Fi: run a normal session (and optionally `adb shell dmesg | grep -i bcmdhd`)
— with the patch, the driver no longer enters PS-poll power save while
connected.

## 4. Rollback

Anything misbehaving → back to stock behaviour:

```sh
adb reboot bootloader
fastboot flash boot kernel-backup/boot.img
fastboot flash dtbo kernel-backup/dtbo.img
fastboot flash vendor_kernel_boot kernel-backup/vendor_kernel_boot.img
fastboot reboot fastboot
fastboot flash system_dlkm kernel-backup/system_dlkm.img
fastboot flash vendor_dlkm kernel-backup/vendor_dlkm.img
fastboot reboot
```

(or `adb root` + `dd` the backups back, same commands as section 1 reversed).

## 5. Honest caveats — read this

1. **A kernel cannot fix broken hardware.** Pixel Wi-Fi chips are known to
   develop *hardware* faults (cracked solder joints under the Wi-Fi IC).
   Test it this way: if the dropouts disappear with this kernel → it was
   software (power-save/thermal). If they continue *identically* → suspect the
   hardware; no kernel, ROM or driver change will fix a failing IC — it needs
   reflow/replacement.
2. **Wi-Fi power-save off costs power**: roughly 100–200 mW extra idle draw
   while Wi-Fi is on. Suspend/sleep is unaffected (PS is re-enabled when the
   device sleeps — the patch only changes the *connected, awake* policy).
3. **−5 °C earlier passive throttling costs ~5 % sustained performance.**
   Emergency/safety trips are untouched: the phone can still protect itself.
4. **Kernel base is 6.1.124** (GKI `android14-6.1`, branch tip — nothing newer
   exists on that branch). The stock factory kernel is 6.1.134 and AICP's own
   kernel was 6.1.145 — you are trading those *later kernel* changes for
   KernelSU + the Wi-Fi/thermal patches. Wi-Fi/Bluetooth **firmware** is not
   part of this flash set; it stays whatever your ROM ships.
5. This is a **GKI-style custom kernel built from Google's source with local
   patches** — not an official Google or KernelSU release. Flash at your own
   risk; keep the backups.
