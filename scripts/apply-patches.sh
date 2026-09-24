#!/bin/bash
# Write the three kernel patches into the synced tree, verify each edit,
# capture them as patch files in the project repo, and commit locally.
# Idempotent: safe to re-run after a partial run or a fresh repo sync.
set -euo pipefail

R=/home/king/kernel-shusky
OUT="/mnt/c/Users/King/Documents/Default Project/patches"
mkdir -p "$OUT"

export GIT_AUTHOR_NAME=King GIT_AUTHOR_EMAIL=king@local
export GIT_COMMITTER_NAME=King GIT_COMMITTER_EMAIL=king@local

echo "== pre-check: worktree status of patch targets =="
for p in private/google-modules/wlan/bcm4398 private/devices/google/zuma; do
    st=$(git -C "$R/$p" status --porcelain)
    if [ -n "$st" ]; then
        echo "[warn] $p has local changes (proceeding — expected on re-run):"
        echo "$st"
    fi
done

# commit a patch file: diff worktree vs HEAD; if diff is empty the change is
# already committed — require the patch file from a previous run instead.
gen_patch() {
    local proj="$1" pathspec="$2" out="$3"
    if [ -n "$(git -C "$proj" diff HEAD -- $pathspec)" ]; then
        git -C "$proj" diff HEAD -- $pathspec > "$out"
    fi
    test -s "$out" || { echo "FAIL: $out empty and no pending diff"; exit 1; }
    echo "[patch] -> $out"
}

# --- step 1: commit the KernelSU-Next setup.sh hooks already in aosp worktree ---
if [ -n "$(git -C "$R/aosp" status --porcelain -- drivers/Makefile drivers/Kconfig)" ]; then
    git -C "$R/aosp" add drivers/Makefile drivers/Kconfig
    git -C "$R/aosp" commit -q -m "KernelSU-Next v3.4.0: drivers Makefile/Kconfig hooks (setup.sh)"
    echo "[commit] aosp: KernelSU hooks"
fi

# --- step 2: CONFIG_KSU=y in gki_defconfig ---
DC="$R/aosp/arch/arm64/configs/gki_defconfig"
if ! grep -q "^CONFIG_KSU=y" "$DC"; then
    printf '\n# KernelSU-Next: built-in root manager\nCONFIG_KSU=y\n' >> "$DC"
    echo "[edit] gki_defconfig: appended CONFIG_KSU=y"
else
    echo "[skip] gki_defconfig already has CONFIG_KSU=y"
fi
gen_patch "$R/aosp" "arch/arm64/configs/gki_defconfig" \
    "$OUT/0001-gki_defconfig-CONFIG_KSU.patch"
if [ -n "$(git -C "$R/aosp" diff HEAD -- arch/arm64/configs/gki_defconfig)" ]; then
    git -C "$R/aosp" commit -q -m "gki_defconfig: enable CONFIG_KSU for KernelSU-Next built-in root" \
        -- arch/arm64/configs/gki_defconfig
    echo "[commit] aosp: CONFIG_KSU"
fi

# --- step 3: Wi-Fi power-save off (bcmdhd4398) ---
python3 - <<'PYEOF'
import pathlib
base = pathlib.Path("/home/king/kernel-shusky")
edits = [
    ("private/google-modules/wlan/bcm4398/dhd_linux.c",
     [("uint power_mode = PM_FAST;", "uint power_mode = PM_OFF;", 2)]),
    ("private/google-modules/wlan/bcm4398/wl_cfg80211.c",
     [("u32 power_mode = suspend ? PM_MAX : PM_FAST;",
       "u32 power_mode = suspend ? PM_MAX : PM_OFF;", 1)]),
]
for rel, subs in edits:
    p = base / rel
    t = p.read_text()
    changed = False
    for old, new, cnt in subs:
        n = t.count(old)
        if n == cnt:
            t = t.replace(old, new)
            changed = True
            print(f"[edit] {rel}: {cnt}x {old!r} -> {new!r}")
        else:
            done = t.count(new)
            assert n == 0 and done >= cnt, \
                f"{rel}: unexpected state: {old!r} found {n}, {new!r} found {done}"
            print(f"[skip] {rel}: already patched ({done}x)")
    if changed:
        p.write_text(t)
print("wifi edits done")
PYEOF

gen_patch "$R/private/google-modules/wlan/bcm4398" "" \
    "$OUT/0002-wifi-disable-power-save.patch"
if [ -n "$(git -C "$R/private/google-modules/wlan/bcm4398" diff HEAD)" ]; then
    git -C "$R/private/google-modules/wlan/bcm4398" add -A
    git -C "$R/private/google-modules/wlan/bcm4398" commit -q \
        -m "bcmdhd4398: disable Wi-Fi power save while active (PM_OFF); keep PM_MAX in suspend"
    echo "[commit] bcm4398: Wi-Fi PM_OFF"
fi

# --- step 4: thermal trips: throttle 5C earlier on CPU/GPU (4 base dtbs) ---
python3 - <<'PYEOF'
import re, pathlib
base = pathlib.Path("/home/king/kernel-shusky/private/devices/google/zuma/dts")
# Stock trips differ per package variant: ipop = 90/90/90/95, foplp = 95/95/100/100
# (big/mid/gpu/little control_temp). Target: 5C earlier on each.
IPOP = {"big_control_temp": ("90000", "85000"),
        "mid_control_temp": ("90000", "85000"),
        "gpu_control_temp": ("90000", "85000"),
        "little_control_temp": ("95000", "90000")}
FOPLP = {"big_control_temp": ("95000", "90000"),
         "mid_control_temp": ("95000", "90000"),
         "gpu_control_temp": ("100000", "95000"),
         "little_control_temp": ("100000", "95000")}
files = [("zuma-a0-ipop.dts", IPOP), ("zuma-a0-foplp.dts", FOPLP),
         ("zuma-b0-ipop.dts", IPOP), ("zuma-b0-foplp.dts", FOPLP)]
for name, labels in files:
    p = base / name
    t = p.read_text()
    changed = 0
    for label, (old, new) in labels.items():
        pat = re.compile(r"(" + label + r":\s*[\w-]+\s*\{\s*\n\s*temperature = <)" + old + r"(>)")
        t, n = pat.subn(lambda m: m.group(1) + new + m.group(2), t)
        if n == 1:
            changed += 1
            print(f"[edit] {name}: {label} {old} -> {new}")
        else:
            pat2 = re.compile(r"(" + label + r":\s*[\w-]+\s*\{\s*\n\s*temperature = <)" + new + r"(>)")
            assert n == 0 and len(pat2.findall(t)) == 1, \
                f"{name}: {label} matched {n} times (neither {old} nor {new})"
            print(f"[skip] {name}: {label} already {new}")
    p.write_text(t)
    print(f"[ok] {name} ({changed} changed)")
print("thermal edits done")
PYEOF

gen_patch "$R/private/devices/google/zuma" "" \
    "$OUT/0003-thermal-earlier-throttle.patch"
if [ -n "$(git -C "$R/private/devices/google/zuma" diff HEAD)" ]; then
    git -C "$R/private/devices/google/zuma" add -A
    git -C "$R/private/devices/google/zuma" commit -q \
        -m "zuma dts: start CPU/GPU passive thermal throttling 5C earlier (cooler peaks)"
    echo "[commit] zuma: thermal trips"
fi

echo
echo "== verification =="
grep -n "CONFIG_KSU=y" "$DC"
grep -n "power_mode = PM_OFF\|PM_MAX : PM_OFF" \
    "$R/private/google-modules/wlan/bcm4398/dhd_linux.c" \
    "$R/private/google-modules/wlan/bcm4398/wl_cfg80211.c"
for f in zuma-a0-ipop zuma-a0-foplp zuma-b0-ipop zuma-b0-foplp; do
    echo "-- $f --"
    grep -A1 "big_control_temp:\|mid_control_temp:\|gpu_control_temp:\|little_control_temp:" \
        "$R/private/devices/google/zuma/dts/$f.dts" | grep "temperature"
done

echo
echo "== git log (per project) =="
for p in aosp private/google-modules/wlan/bcm4398 private/devices/google/zuma; do
    echo "--- $p ---"
    git -C "$R/$p" log --oneline -3
done

echo
echo "== patch files =="
ls -la "$OUT"
echo "ALL DONE"
