#!/usr/bin/env bash
# amd.sh - AMD GPU query abstraction module
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_AMD_LOADED:-}" ]] && return 0
_SYSTEM_AMD_LOADED=1

# Source sensors module for lm-sensors queries
_AMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_AMD_DIR/sensors.sh"

# Check if AMD GPU is available
# Usage: amd_gpu_available && echo "AMD GPU detected"
amd_gpu_available() {
    # Check for amdgpu driver in lspci or for AMD GPU sensors
    if command -v lspci &>/dev/null; then
        lspci -k 2>/dev/null | grep -qE "Kernel driver in use: amdgpu" && return 0
    fi
    # Fallback: check if sensors reports amdgpu
    sensors_available && sensors 2>/dev/null | grep -q "amdgpu" && return 0
    return 1
}

# Get AMD GPU temperature (prefers edge, falls back to junction)
# Usage: temp=$(amd_get_temp)
# Returns: Temperature in Celsius (integer) or empty
amd_get_temp() {
    sensors_available || return 1
    sensors_get_amd_gpu_temp
}

# Get AMD GPU edge temperature specifically
# Usage: temp=$(amd_get_edge_temp)
amd_get_edge_temp() {
    sensors_available || return 1
    sensors_get_amd_edge_temp
}

# Get AMD GPU junction (hotspot) temperature
# Usage: temp=$(amd_get_junction_temp)
amd_get_junction_temp() {
    sensors_available || return 1
    sensors_get_amd_junction_temp
}

# Get AMD GPU fan speed in RPM
# Usage: rpm=$(amd_get_fan_speed)
# Returns: Fan speed in RPM or empty
amd_get_fan_speed() {
    sensors_available || return 1
    # Look for fan1 in amdgpu sensor output
    sensors 2>/dev/null | awk '/amdgpu/,/^$/' | grep -E "^fan1:" | grep -oP '[0-9]+(?= RPM)'
}

# Get AMD GPU power usage via hwmon (if available)
# Usage: power=$(amd_get_power)
# Returns: Power in watts or empty
amd_get_power() {
    local power_file
    for hwmon in /sys/class/hwmon/hwmon*/; do
        if [[ -f "${hwmon}name" ]] && grep -q "amdgpu" "${hwmon}name" 2>/dev/null; then
            power_file="${hwmon}power1_average"
            if [[ -f "$power_file" ]]; then
                local power_uw
                power_uw=$(cat "$power_file" 2>/dev/null)
                [[ -n "$power_uw" ]] && echo $((power_uw / 1000000))
                return 0
            fi
        fi
    done
    return 1
}

# Get AMD GPU VRAM usage via sysfs (if available)
# Usage: read -r used total <<< "$(amd_get_vram_usage)"
# Returns: "used_bytes total_bytes" or empty
amd_get_vram_usage() {
    local gpu_path
    for card in /sys/class/drm/card*/device; do
        if [[ -f "${card}/vendor" ]] && grep -q "0x1002" "${card}/vendor" 2>/dev/null; then
            local used total
            used=$(cat "${card}/mem_info_vram_used" 2>/dev/null)
            total=$(cat "${card}/mem_info_vram_total" 2>/dev/null)
            [[ -n "$used" ]] && [[ -n "$total" ]] && echo "$used $total"
            return 0
        fi
    done
    return 1
}
