#!/usr/bin/env bash
# xfce4-genmon-plugin script: discrete AMD GPU (load, VRAM, power), network rate,
# system RAM, swap and free space and disk I/O on /. Panel text is two lines:
#   GPU   4%  15.8/15.9G   27W  NET ↓ 1.2M ↑ 0.1M     SSD  88%    R  12K
#   MEM  12%   3.6/30.0G        SWP   2%   1.2/62.0G  53.0G free  W 1.2M
# The SSD column turns yellow under 8% free and red under 2% free.
# Hover for details; click opens Mission Center.

# System RAM and swap from /proc/meminfo (kB). The systemload plugin's mem bar
# gets stuck and stops redrawing, so these are shown here as text instead.
read -r mpct mused mtotal mavail mcache spct sused stotal < <(awk '
  { v[$1] = $2 }
  END {
    t = v["MemTotal:"]; a = v["MemAvailable:"]; u = t - a; g = 1048576
    st = v["SwapTotal:"]; su = st - v["SwapFree:"]
    printf "%d %.1f %.1f %d %d %d %.1f %.1f\n", u * 100 / t, u / g, t / g, a / 1024,
      (v["Cached:"] + v["Buffers:"] + v["SReclaimable:"]) / 1024,
      (st > 0 ? su * 100 / st : 0), su / g, st / g
  }' /proc/meminfo)
memtxt=$(printf 'MEM %3d%%  %4s/%sG' "$mpct" "$mused" "$mtotal")
swptxt=$(printf 'SWP %3d%%  %4s/%sG' "$spct" "$sused" "$stotal")

# Network rate on the default-route interface: byte counters are compared with
# the previous run's, kept in a small state file.
iface=$(ip -o route show default 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
rate() {  # bytes/s -> fixed 5-char "  12K" / " 1.2M" / " 120M"
  awk -v b="$1" 'BEGIN { k = b / 1024; m = k / 1024
    if (k < 1000) printf "%4dK", k; else if (m < 100) printf "%4.1fM", m; else if (m < 1000) printf "%4dM", m; else printf "%4.1fG", m / 1024 }'
}
down=0; up=0; rx=0; tx=0
if [ -n "$iface" ] && [ -r "/sys/class/net/$iface/statistics/rx_bytes" ]; then
  rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
  tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
  now=${EPOCHREALTIME/[.,]/}   # microseconds
  state="${XDG_RUNTIME_DIR:-/tmp}/sys-genmon.net"
  if read -r piface prx ptx pt 2>/dev/null <"$state" && [ "$piface" = "$iface" ] \
     && (( now > pt && rx >= prx && tx >= ptx )); then
    down=$(( (rx - prx) * 1000000 / (now - pt) ))
    up=$(( (tx - ptx) * 1000000 / (now - pt) ))
  fi
  echo "$iface $rx $tx $now" >"$state"
fi
nettxt="NET ↓$(rate "$down") ↑$(rate "$up")"

# Free space on / (replaces the fsguard plugin, whose modal low-space warning
# froze its own updates until dismissed).
read -r dsize davail dused < <(df -B1 --output=size,avail,used / | tail -1)
dpct=$(( dused * 100 / (dused + davail) ))
dfree=$(awk -v b="$davail" 'BEGIN { printf "%.1f", b / 1073741824 }')
dsk1=$(printf '%-10s' "$(printf 'SSD %3d%%' "$dpct")")
dsk2=$(printf '%-10s' "${dfree}G free")
dfreepct=$(( davail * 100 / dsize ))
dcol=""
(( dfreepct < 8 )) && dcol="#e5c07b"
(( dfreepct < 2 )) && dcol="#ff5555"
if [ -n "$dcol" ]; then
  dsk1="<span foreground='$dcol' weight='bold'>$dsk1</span>"
  dsk2="<span foreground='$dcol' weight='bold'>$dsk2</span>"
fi

memtool="<b>Memory</b>
Used:      ${mused} / ${mtotal} GiB (${mpct}%)
Available: ${mavail} MiB
Cache:     ${mcache} MiB
Swap:      ${sused} / ${stotal} GiB (${spct}%)

<b>Network</b> (${iface:-no default route})
Down:      $(rate "$down")/s   (total $(( rx / 1048576 )) MiB)
Up:        $(rate "$up")/s   (total $(( tx / 1048576 )) MiB)

<b>Disk</b> (/)
Free:      ${dfree} GiB of $(( dsize / 1073741824 )) GiB (${dpct}% used)"

# Read/write rate of the disk holding / (replaces the diskperf plugin): sector
# counters from /sys/block/<disk>/stat, compared with the previous run's.
disk=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null | head -1)
drd=0; dwr=0
if [ -n "$disk" ] && read -r _ _ rsec _ _ _ wsec _ <"/sys/block/$disk/stat"; then
  dnow=${EPOCHREALTIME/[.,]/}
  dstate="${XDG_RUNTIME_DIR:-/tmp}/sys-genmon.disk"
  if read -r pdisk prs pws pdt 2>/dev/null <"$dstate" && [ "$pdisk" = "$disk" ] \
     && (( dnow > pdt && rsec >= prs && wsec >= pws )); then
    drd=$(( (rsec - prs) * 512 * 1000000 / (dnow - pdt) ))
    dwr=$(( (wsec - pws) * 512 * 1000000 / (dnow - pdt) ))
  fi
  echo "$disk $rsec $wsec $dnow" >"$dstate"
fi
dsk1="$dsk1  R$(rate "$drd")"
dsk2="$dsk2  W$(rate "$dwr")"
memtool="$memtool
Read:      $(rate "$drd")/s   Write: $(rate "$dwr")/s   (${disk:-?})"

# Pick the amdgpu card with the most VRAM (skips the iGPU).
dev=""; best=0
for d in /sys/class/drm/card[0-9]/device /sys/class/drm/card[0-9][0-9]/device; do
  [ -r "$d/mem_info_vram_total" ] || continue
  t=$(<"$d/mem_info_vram_total")
  (( t > best )) && { best=$t; dev=$d; }
done
[ -n "$dev" ] || { printf '<txt> GPU n/a  %s  %s \n %s  %s  %s </txt>\n<tool>%s</tool>\n' "$nettxt" "$dsk1" "$memtxt" "$swptxt" "$dsk2" "$memtool"; exit 0; }

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

printf '<txt> GPU %3d%%  %4s/%sG  %3dW  %s     %s \n %s        %s  %s </txt>\n' \
  "$busy" "$(gib "$vu")" "$(gib "$vt")" $(( pw / 1000000 )) "$nettxt" "$dsk1" "$memtxt" "$swptxt" "$dsk2"

cat <<EOF
<tool><b>Discrete GPU</b> ($(basename "$(dirname "$dev")"))
Load:      ${busy}%   (memory controller ${membusy}%)
VRAM:      $(mib "$vu") / $(mib "$vt") MiB
GTT:       $(mib "$gu") MiB (system RAM used by GPU)
Power:     $(( pw / 1000000 )) W / $(( cap / 1000000 )) W cap
Clocks:    core $(( sclk / 1000000 )) MHz, mem $(( mclk / 1000000 )) MHz
Temps:     edge ${temp[edge]:-?}°C, hotspot ${temp[junction]:-?}°C, mem ${temp[mem]:-?}°C
Fan:       ${fan} rpm

${memtool}</tool>
<txtclick>missioncenter</txtclick>
EOF
