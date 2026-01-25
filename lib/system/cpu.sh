#!/usr/bin/env bash
# cpu.sh - CPU metrics and monitoring functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_CPU_LOADED:-}" ]] && return 0
_SYSTEM_CPU_LOADED=1

# Source sensors module for lm-sensors queries
_SYSTEM_CPU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SYSTEM_CPU_DIR/sensors.sh"

# Get CPU usage percentage (requires two samples)
# Usage: cpu_percent=$(get_cpu_usage_live)
# Returns: Integer percentage (0-100)
get_cpu_usage_live() {
    local cpu1 cpu2
    local user1 nice1 system1 idle1 iowait1 irq1 softirq1
    local user2 nice2 system2 idle2 iowait2 irq2 softirq2
    local total1 total2 idle_total1 idle_total2
    local diff_idle diff_total cpu_percent

    # First sample
    read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 _ < /proc/stat

    # Short delay for delta
    sleep 0.1

    # Second sample
    read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 _ < /proc/stat

    # Calculate totals
    idle_total1=$((idle1 + iowait1))
    idle_total2=$((idle2 + iowait2))
    total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1))
    total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2))

    diff_idle=$((idle_total2 - idle_total1))
    diff_total=$((total2 - total1))

    if [[ $diff_total -gt 0 ]]; then
        cpu_percent=$(( (diff_total - diff_idle) * 100 / diff_total ))
    else
        cpu_percent=0
    fi

    echo "$cpu_percent"
}

# Get CPU temperature from sensors
# Usage: cpu_temp=$(get_cpu_temp_live)
# Returns: Temperature in Celsius (integer) or empty if unavailable
get_cpu_temp_live() {
    local temp

    # Try lm-sensors first via sensors module
    if sensors_available; then
        temp=$(sensors_get_cpu_temp)
        [[ -n "$temp" ]] && { echo "$temp"; return; }
    fi

    # Try /sys/class/hwmon
    for hwmon in /sys/class/hwmon/hwmon*/temp*_input; do
        if [[ -f "$hwmon" ]]; then
            local label_file="${hwmon%_input}_label"
            if [[ -f "$label_file" ]]; then
                local label
                label=$(cat "$label_file" 2>/dev/null)
                if [[ "$label" =~ (Core|CPU|Tctl|Package) ]]; then
                    temp=$(cat "$hwmon" 2>/dev/null)
                    [[ -n "$temp" ]] && { echo $((temp / 1000)); return; }
                fi
            fi
        fi
    done

    # Try /sys/class/thermal
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        [[ -n "$temp" ]] && { echo $((temp / 1000)); return; }
    fi

    echo ""
}

# Get CPU frequency in MHz
# Usage: freq=$(get_cpu_freq_live)
get_cpu_freq_live() {
    local freq

    # Try /proc/cpuinfo
    freq=$(awk '/^cpu MHz/ {print int($4); exit}' /proc/cpuinfo 2>/dev/null)
    [[ -n "$freq" ]] && { echo "$freq"; return; }

    # Try /sys/devices
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
        [[ -n "$freq" ]] && { echo $((freq / 1000)); return; }
    fi

    echo ""
}

# Get load average (1 min)
# Usage: load=$(get_load_avg_live)
get_load_avg_live() {
    awk '{print $1}' /proc/loadavg 2>/dev/null
}
