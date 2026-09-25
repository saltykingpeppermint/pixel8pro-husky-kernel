#!/bin/bash
# Post-build verification — run AFTER the monitor reports BUILD_OK and BEFORE
# packaging anything. Proves the dist Image is OUR source build with KernelSU
# and that every module/DTB in the flash set belongs to this exact build.
# Exit 0 = safe to package/flash. Exit 1 = do not flash.
set -u
KSRC=/home/king/kernel-shusky
DIST="$KSRC/out/shusky/dist"
PDIR="/mnt/c/Users/King/Documents/Default Project"
PARSER="$PDIR/scripts/parse-trips.py"
EXTRACT="$KSRC/aosp/scripts/extract-ikconfig"
FAIL=0
ok()   { echo "  [ok]   $*"; }
bad()  { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }
warn() { echo "  [warn] $*"; }

HEAD12=$(git -C "$KSRC/aosp" rev-parse --short=12 HEAD)

echo "=== 1. dist inventory ==="
for f in Image boot.img dtbo.img dtb.img vendor_dlkm.img system_dlkm.img \
         vendor_kernel_boot.img modules.load system_dlkm.modules.load \
         vendor_dlkm.modules.load; do
    if [ -f "$DIST/$f" ]; then
        ok "$f  ($(stat -c '%s' "$DIST/$f") bytes, $(stat -c '%y' "$DIST/$f" | cut -c1-16))"
    else
        bad "MISSING: $f"
    fi
done

echo
echo "=== 2. Image identity (must be our source build, HEAD=$HEAD12) ==="
BANNER=$(grep -a -m1 -o 'Linux version 6\.1[^ ]*' "$DIST/Image" 2>/dev/null | head -1)
if [ -z "$BANNER" ]; then
    bad "no linux_banner in Image"
    UTS=""
else
    UTS=${BANNER##* }
    echo "  banner: $BANNER"
    case "$UTS" in
        6.1.124-android14-11-g"$HEAD12") ok "UTS matches aosp HEAD exactly" ;;
        6.1.124-android14-11-g8d713f9e8e7b)
            bad "Image is still Google's downloaded PREBUILT GKI — rebuild needed" ;;
        *) bad "unexpected UTS '$UTS' (want 6.1.124-android14-11-g$HEAD12)" ;;
    esac
fi

echo
echo "=== 3. KernelSU built in ==="
if [ -f "$EXTRACT" ] && bash "$EXTRACT" "$DIST/Image" 2>/dev/null | grep -q '^CONFIG_KSU=y'; then
    ok "CONFIG_KSU=y in embedded ikconfig"
else
    bad "CONFIG_KSU=y NOT found in Image ikconfig"
fi
KSU_STR=$(grep -a -c 'KernelSU' "$DIST/Image" 2>/dev/null || true)
echo "  KernelSU strings in Image: $KSU_STR (informational)"

echo
echo "=== 4. vermagic consistency (Image vs flash-set modules) ==="
if [ -n "$UTS" ]; then
    for m in bcmdhd4398.ko mac80211.ko 8021q.ko bluetooth.ko cfg80211.ko; do
        f="$DIST/$m"
        if [ -f "$f" ]; then
            vm=$(strings -a "$f" | grep -m1 -o '6\.1\.[0-9]*-android14-11-g[0-9a-f]*' || true)
            if [ "$vm" = "$UTS" ]; then ok "$m vermagic == Image UTS"
            else bad "$m vermagic '$vm' != Image '$UTS'"
            fi
        else
            warn "$m not in dist root (may live in a subdir image)"
        fi
    done
else
    bad "skipped: no UTS from Image"
fi

echo
echo "=== 5. wifi power-save patch ==="
# Pin the path: this tree carries SEVERAL Broadcom drivers (bcm4389/4390/4383/
# dhd43752p — other chips, never patched); a blind `find | head -1` picked
# bcm4389 first and produced a false failure. husky uses BCM4398 only.
DHD="$KSRC/private/google-modules/wlan/bcm4398/dhd_linux.c"
if [ -f "$DHD" ]; then
    c1=$(grep -c 'uint power_mode = PM_OFF;' "$DHD" || true)
    wlc="${DHD%/*}/wl_cfg80211.c"
    c2=0
    [ -f "$wlc" ] && c2=$(grep -c 'suspend ? PM_MAX : PM_OFF' "$wlc" || true)
    if [ "$c1" -ge 2 ] && [ "$c2" -ge 1 ]; then
        ok "source patched (dhd=$c1 hits, wl_cfg80211=$c2 hits)"
    else
        bad "patch markers missing (dhd=$c1, wl=$c2)"
    fi
    if [ -f "$DIST/bcmdhd4398.ko" ] && [ "$DIST/bcmdhd4398.ko" -nt "$DHD" ]; then
        ok "bcmdhd4398.ko rebuilt after patch"
    else
        bad "bcmdhd4398.ko older than patched source (stale module?)"
    fi
else
    bad "bcm4398 dhd_linux.c missing at $DHD"
fi

echo
echo "=== 6. thermal trips in built DTBs ==="
trip() { python3 "$PARSER" "$1" 2>/dev/null | awk -F= -v n="$2" '$1==n {print $2; exit}'; }
expect_dtb() { # file node want
    local got; got=$(trip "$1" "$2")
    if [ "$got" = "$3" ]; then ok "$(basename "$1"): $2 = $got mC"
    else bad "$(basename "$1"): $2 = ${got:-<missing>} (want $3)"
    fi
}
if [ -f "$PARSER" ]; then
    for dtb in zuma-a0-foplp zuma-b0-foplp; do
        [ -f "$DIST/$dtb.dtb" ] || { warn "missing $dtb.dtb in dist root"; continue; }
        expect_dtb "$DIST/$dtb.dtb" big-control-temp 90000
        expect_dtb "$DIST/$dtb.dtb" mid-control-temp 90000
        expect_dtb "$DIST/$dtb.dtb" little-control-temp 95000
        expect_dtb "$DIST/$dtb.dtb" gpu-control-temp 95000
    done
    for dtb in zuma-a0-ipop zuma-b0-ipop; do
        [ -f "$DIST/$dtb.dtb" ] || { warn "missing $dtb.dtb in dist root"; continue; }
        expect_dtb "$DIST/$dtb.dtb" big-control-temp 85000
        expect_dtb "$DIST/$dtb.dtb" mid-control-temp 85000
        expect_dtb "$DIST/$dtb.dtb" little-control-temp 90000
        expect_dtb "$DIST/$dtb.dtb" gpu-control-temp 85000
    done
    if [ -f "$DIST/dtb.img" ]; then
        out=$(python3 "$PARSER" "$DIST/dtb.img" 2>/dev/null)
        echo "$out" | grep -q '^big-control-temp=90000$' && \
        echo "$out" | grep -q '^big-control-temp=85000$' \
            && ok "dtb.img carries foplp+ipop patched trips" \
            || bad "dtb.img trips not both patched ($(echo "$out" | wc -l) trips found)"
    fi
    if [ -f "$DIST/dtbo.img" ]; then
        n=$(python3 "$PARSER" "$DIST/dtbo.img" 2>/dev/null | wc -l)
        if [ "$n" -ge 16 ]; then
            out=$(python3 "$PARSER" "$DIST/dtbo.img" 2>/dev/null)
            echo "$out" | grep -q '^big-control-temp=90000$' && \
            echo "$out" | grep -q '^big-control-temp=85000$' \
                && ok "dtbo.img embeds base DTBs with patched trips" \
                || bad "dtbo.img has $n trips but not both patched values"
        else
            warn "dtbo.img: $n control-temp trips (overlays only? base dtb rides dtb/vendor_kernel_boot — still flashed)"
        fi
    fi
    # vendor_kernel_boot: bootloader DTB source candidate — unpack + check
    if [ -f "$DIST/vendor_kernel_boot.img" ]; then
        rm -rf /tmp/vkbchk && mkdir -p /tmp/vkbchk
        if python3 "$KSRC/tools/mkbootimg/unpack_bootimg.py" \
              --boot_img "$DIST/vendor_kernel_boot.img" --out /tmp/vkbchk >/dev/null 2>&1 \
           && [ -f /tmp/vkbchk/dtb ]; then
            out=$(python3 "$PARSER" /tmp/vkbchk/dtb 2>/dev/null)
            if echo "$out" | grep -q '^big-control-temp=90000$' && \
               echo "$out" | grep -q '^big-control-temp=85000$'; then
                ok "vendor_kernel_boot dtb has both patched trip sets"
            else
                bad "vendor_kernel_boot dtb trips not patched ($(echo "$out" | wc -l) trips)"
            fi
        else
            warn "could not unpack vendor_kernel_boot dtb component"
        fi
        rm -rf /tmp/vkbchk
    fi
else
    bad "parse-trips.py missing at $PARSER"
fi

echo
echo "=== 7. KMI symbol list violations ==="
V="$KSRC/out/bazel-out/k8-fastbuild/bin/private/devices/google/shusky/kernel_kmi_symbol_list_violations_checked"
ALT=$(find -L "$KSRC/out/bazel-out" -maxdepth 8 -name 'kernel_kmi_symbol_list_violations_checked' 2>/dev/null | head -1)
[ -f "$V" ] || V="$ALT"
if [ -n "$V" ] && [ -f "$V" ]; then
    if [ -s "$V" ]; then warn "violations file non-empty:"; head -10 "$V"
    else ok "KMI violations file present and empty (0 violations)"
    fi
else
    warn "KMI violations file not found (bounded search)"
fi

echo
echo "=== 8. fips140 not referenced by any load list ==="
fips_ok=1
for h in "$DIST"/*.load; do
    [ -f "$h" ] || continue
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        case "$line" in
            *ufs-pixel-fips140*) ;;   # expected, fine
            *fips140*) echo "  [FAIL] $(basename "$h"): $line"; fips_ok=0; FAIL=$((FAIL+1)) ;;
        esac
    done < <(grep 'fips140' "$h" 2>/dev/null || true)
done
[ "$fips_ok" -eq 1 ] && ok "no bare fips140.ko referenced (only ufs-pixel variant)"

echo
if [ "$FAIL" -eq 0 ]; then
    echo "VERIFY_OK — dist is safe to package"
    exit 0
else
    echo "VERIFY_FAILED — $FAIL check(s) failed, do NOT flash"
    exit 1
fi
