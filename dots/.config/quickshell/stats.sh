#!/bin/bash
# Quickshell Liquid Glass — System Stats Daemon
# Outputs key=value pairs to /tmp/qs_stats.txt every 2 seconds

# ---- CPU baseline ----
read _ user nice system idle iowait irq softirq steal _ _ < /proc/stat
prev_idle=$((idle + iowait))
prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))

# ---- Network baseline ----
iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
prev_rx=0; prev_tx=0
if [ -n "$iface" ] && [ -f "/sys/class/net/$iface/statistics/rx_bytes" ]; then
    prev_rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
    prev_tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
fi

format_speed() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ] 2>/dev/null; then
        echo "$((bytes / 1048576))M/s"
    elif [ "$bytes" -ge 1024 ] 2>/dev/null; then
        echo "$((bytes / 1024))K/s"
    else
        echo "${bytes}B/s"
    fi
}

while true; do
    sleep 2

    # ===== Memory =====
    mem=$(free | awk '/Mem/ {print int($3/$2 * 100.0)}')

    # ===== CPU =====
    read _ user nice system idle iowait irq softirq steal _ _ < /proc/stat
    current_idle=$((idle + iowait))
    current_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    diff_idle=$((current_idle - prev_idle))
    diff_total=$((current_total - prev_total))
    [ "$diff_total" -eq 0 ] && diff_total=1
    cpu=$((100 * (diff_total - diff_idle) / diff_total))
    prev_idle=$current_idle
    prev_total=$current_total

    # ===== Temperature =====
    temp=""
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    fi

    # ===== Volume & Mic =====
    vol=""
    vol_muted="false"
    mic=""
    mic_muted="false"
    if command -v pamixer &>/dev/null; then
        vol=$(timeout 1 pamixer --get-volume 2>/dev/null || echo "")
        vol_muted=$(timeout 1 pamixer --get-mute 2>/dev/null || echo "false")
        mic=$(timeout 1 pamixer --default-source --get-volume 2>/dev/null || echo "")
        mic_muted=$(timeout 1 pamixer --default-source --get-mute 2>/dev/null || echo "false")
    fi

    # ===== Network =====
    iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
    net=""
    net_type=""
    net_down=""
    net_up=""
    if [ -n "$iface" ]; then
        if [ -d "/sys/class/net/$iface/wireless" ]; then
            net=$(iwgetid -r 2>/dev/null || echo "WiFi")
            net_type="wifi"
        else
            net=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            net_type="ethernet"
        fi
        # Speed calculation
        if [ -f "/sys/class/net/$iface/statistics/rx_bytes" ]; then
            curr_rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            curr_tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            rx_rate=$(( (curr_rx - prev_rx) / 2 ))
            tx_rate=$(( (curr_tx - prev_tx) / 2 ))
            [ "$rx_rate" -lt 0 ] 2>/dev/null && rx_rate=0
            [ "$tx_rate" -lt 0 ] 2>/dev/null && tx_rate=0
            net_down=$(format_speed "$rx_rate")
            net_up=$(format_speed "$tx_rate")
            prev_rx=$curr_rx
            prev_tx=$curr_tx
        fi
    fi

    # ===== Battery =====
    bat=""
    bat_status=""
    if ls /sys/class/power_supply/BAT* 1>/dev/null 2>&1; then
        bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)
        bat_status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1)
    fi

    # ===== Music =====
    music=""
    music_status=""
    if command -v playerctl &>/dev/null; then
        music_status=$(timeout 1 playerctl status 2>/dev/null || echo "")
        if [ "$music_status" = "Playing" ] || [ "$music_status" = "Paused" ]; then
            artist=$(timeout 1 playerctl metadata artist 2>/dev/null || echo "")
            title=$(timeout 1 playerctl metadata title 2>/dev/null || echo "")
            if [ -n "$title" ]; then
                if [ -n "$artist" ]; then
                    music="$artist - $title"
                else
                    music="$title"
                fi
                # Sanitize: remove newlines, truncate to 45 chars
                music=$(printf '%s' "$music" | tr '\n\r' '  ' | cut -c1-45)
            fi
        fi
    fi

    # ===== Write output =====
    cat > /tmp/qs_stats.txt << STATSEOF
mem=$mem
cpu=$cpu
temp=$temp
vol=$vol
vol_muted=$vol_muted
mic=$mic
mic_muted=$mic_muted
net=$net
net_type=$net_type
net_down=$net_down
net_up=$net_up
bat=$bat
bat_status=$bat_status
music=$music
music_status=$music_status
STATSEOF

done
