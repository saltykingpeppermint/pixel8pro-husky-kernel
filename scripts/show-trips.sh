#!/bin/bash
# Show current control_temp values across the 4 base dts files.
set -uo pipefail
D=/home/king/kernel-shusky/private/devices/google/zuma/dts
for f in zuma-a0-ipop zuma-a0-foplp zuma-b0-ipop zuma-b0-foplp; do
    echo "-- $f --"
    grep -A1 "big_control_temp:\|mid_control_temp:\|gpu_control_temp:\|little_control_temp:" "$D/$f.dts" | grep "temperature"
done
