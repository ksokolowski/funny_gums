#!/usr/bin/env bash
# sensors.sh - lm-sensors abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_SENSORS_LOADED:-}" ]] && return 0
_SYSTEM_SENSORS_LOADED=1

# Check if lm-sensors is installed
# Usage: sensors_available && echo "sensors installed"
sensors_available() {
    command -v sensors &>/dev/null
}

# Get CPU temperature from sensors
# Usage: cpu_temp=$(sensors_get_cpu_temp)
# Returns: Temperature in Celsius (integer) or empty if unavailable
sensors_get_cpu_temp() {
    sensors_available || return 1
    local temp
    temp=$(sensors 2>/dev/null | grep -E "(Core 0|Tctl|CPU|Package)" | head -1 | grep -oP '\+\K[0-9]+(?=\.[0-9]*°C)')
    [[ -n "$temp" ]] && echo "$temp"
}

# Get AMD GPU temperature (edge sensor)
# Usage: temp=$(sensors_get_amd_gpu_temp)
# Returns: Temperature in Celsius (integer) or empty
sensors_get_amd_gpu_temp() {
    sensors_available || return 1
    local temp
    temp=$(sensors 2>/dev/null | grep -E "(edge|junction)" | head -1 | grep -oP '\+\K[0-9]+(?=\.[0-9]*°C)')
    [[ -n "$temp" ]] && echo "$temp"
}

# Get AMD GPU edge temperature specifically
# Usage: temp=$(sensors_get_amd_edge_temp)
sensors_get_amd_edge_temp() {
    sensors_available || return 1
    local temp
    temp=$(sensors 2>/dev/null | grep -E "^edge:" | head -1 | grep -oP '\+\K[0-9]+(?=\.[0-9]*°C)')
    [[ -n "$temp" ]] && echo "$temp"
}

# Get AMD GPU junction (hotspot) temperature
# Usage: temp=$(sensors_get_amd_junction_temp)
sensors_get_amd_junction_temp() {
    sensors_available || return 1
    local temp
    temp=$(sensors 2>/dev/null | grep -E "^junction:" | head -1 | grep -oP '\+\K[0-9]+(?=\.[0-9]*°C)')
    [[ -n "$temp" ]] && echo "$temp"
}

# Get all temperature readings
# Usage: sensors_get_all_temps
# Returns: Lines of "chip|sensor|temp"
sensors_get_all_temps() {
    sensors_available || return 1
    local current_chip=""
    sensors 2>/dev/null | while IFS= read -r line; do
        # Detect chip header (no colon at end of first word, contains hyphen)
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)-([a-zA-Z0-9]+)$ ]]; then
            current_chip="$line"
            continue
        fi
        # Detect temperature line
        if [[ "$line" =~ ^([^:]+):.*\+([0-9]+)\.[0-9]+°C ]]; then
            local sensor="${BASH_REMATCH[1]}"
            local temp="${BASH_REMATCH[2]}"
            # Clean up sensor name
            sensor=$(echo "$sensor" | sed 's/^ *//;s/ *$//')
            echo "${current_chip}|${sensor}|${temp}"
        fi
    done
}

# Get fan speed readings
# Usage: sensors_get_fan_speeds
# Returns: Lines of "fan_name|rpm"
sensors_get_fan_speeds() {
    sensors_available || return 1
    sensors 2>/dev/null | grep -E "fan[0-9]*:" | while IFS= read -r line; do
        if [[ "$line" =~ ^([^:]+):.*([0-9]+)\ RPM ]]; then
            local fan="${BASH_REMATCH[1]}"
            local rpm="${BASH_REMATCH[2]}"
            fan=$(echo "$fan" | sed 's/^ *//;s/ *$//')
            echo "${fan}|${rpm}"
        fi
    done
}
