#!/system/bin/sh
# Full thermal trip audit vs PATCHES.md expected (BIG/MID 85/90, LITTLE 90/95, G3D 85/95)
echo "=== zones ==="
for z in /sys/class/thermal/thermal_zone*; do
    t=$(cat $z/type 2>/dev/null)
    echo "$(basename $z): $t"
done
echo
echo "=== trips with types ==="
for z in /sys/class/thermal/thermal_zone*; do
    name=$(cat $z/type 2>/dev/null)
    case "$name" in
        CPU0-1|CPU2-3|CPU4-5|CPU6-7|prime|mid|little|BIG|MID|LITTLE|G3D|GPU*|cpu*) ;;
        *) continue ;;
    esac
    echo "--- $name ($(basename $z))"
    i=0
    while [ -f "$z/trip_point_${i}_temp" ]; do
        temp=$(cat $z/trip_point_${i}_temp 2>/dev/null)
        typ=$(cat $z/trip_point_${i}_type 2>/dev/null)
        echo "  trip$i: $temp ($typ)"
        i=$((i+1))
    done
done
echo "=== DONE ==="
