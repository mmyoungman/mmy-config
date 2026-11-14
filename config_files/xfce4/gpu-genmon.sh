#!/usr/bin/env bash
# xfce4-genmon-plugin script: load, VRAM and power for the discrete AMD GPU.
# Panel text: "GPU  4%  15.8/15.9G  27W"; hover for details; click opens Mission Center.

# Pick the amdgpu card with the most VRAM (skips the iGPU).
dev=""; best=0
for d in /sys/class/drm/card[0-9]/device /sys/class/drm/card[0-9][0-9]/device; do
  [ -r "$d/mem_info_vram_total" ] || continue
  t=$(<"$d/mem_info_vram_total")
  (( t > best )) && { best=$t; dev=$d; }
done
[ -n "$dev" ] || { echo "<txt>GPU n/a</txt>"; exit 0; }

hw=$(echo "$dev"/hwmon/hwmon*)
rd() { [ -r "$1" ] && cat "$1" 2>/dev/null || echo 0; }

busy=$(rd "$dev/gpu_busy_percent")
membusy=$(rd "$dev/mem_busy_percent")
vu=$(rd "$dev/mem_info_vram_used")
vt=$(rd "$dev/mem_info_vram_total")
gu=$(rd "$dev/mem_info_gtt_used")

pw=$(rd "$hw/power1_average"); [ "$pw" = 0 ] && pw=$(rd "$hw/power1_input")
cap=$(rd "$hw/power1_cap")
sclk=$(rd "$hw/freq1_input"); mclk=$(rd "$hw/freq2_input")
fan=$(rd "$hw/fan1_input")

# Temperatures by label (edge / junction / mem), in °C.
declare -A temp
for l in "$hw"/temp*_label; do
  [ -r "$l" ] || continue
  temp[$(<"$l")]=$(( $(rd "${l%_label}_input") / 1000 ))
done

gib() { awk -v b="$1" 'BEGIN{printf "%.1f", b/1073741824}'; }
mib() { echo $(( $1 / 1048576 )); }

printf '<txt> GPU %3d%%  %s/%sG  %3dW </txt>\n' \
  "$busy" "$(gib "$vu")" "$(gib "$vt")" $(( pw / 1000000 ))

cat <<EOF
<tool><b>Discrete GPU</b> ($(basename "$(dirname "$dev")"))
Load:      ${busy}%   (memory controller ${membusy}%)
VRAM:      $(mib "$vu") / $(mib "$vt") MiB
GTT:       $(mib "$gu") MiB (system RAM used by GPU)
Power:     $(( pw / 1000000 )) W / $(( cap / 1000000 )) W cap
Clocks:    core $(( sclk / 1000000 )) MHz, mem $(( mclk / 1000000 )) MHz
Temps:     edge ${temp[edge]:-?}°C, hotspot ${temp[junction]:-?}°C, mem ${temp[mem]:-?}°C
Fan:       ${fan} rpm</tool>
<txtclick>missioncenter</txtclick>
EOF
