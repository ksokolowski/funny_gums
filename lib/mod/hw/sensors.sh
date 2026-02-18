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

# Cache variable for sensors output
_SENSORS_CACHE=""

# Update sensors cache
# Usage: sensors_update_cache
sensors_update_cache() {
    sensors_available || return 1
    _SENSORS_CACHE=$(sensors 2>/dev/null)
}

# Validate temperature value
# Usage: _is_valid_temp "65261.8"
# Returns: 0 if valid, 1 if outlier
_is_valid_temp() {
    local temp="${1%\.*}" # Integer part
    temp="${temp#+}"      # Remove leading +

    # Check for empty or non-integer
    [[ -z "$temp" || ! "$temp" =~ ^-?[0-9]+$ ]] && return 1

    # Filter out impossible temps
    ((temp < -50 || temp > 150)) && return 1

    return 0
}

# Get CPU temperature (Smart selection)
# Prioritizes: Tctl > Package > Core 0
# Usage: cpu_temp=$(sensors_get_cpu_temp_smart)
sensors_get_cpu_temp_smart() {
    sensors_available || return 1
    local output
    output="${_SENSORS_CACHE:-$(sensors 2>/dev/null)}"

    local temp=""

    # Try Tctl (AMD)
    temp=$(echo "$output" | grep -m1 "Tctl:" | grep -oP '\+\K[0-9]+\.[0-9]+')
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return
    fi

    # Try Package id 0 (Intel)
    temp=$(echo "$output" | grep -m1 "Package id 0:" | grep -oP '\+\K[0-9]+\.[0-9]+')
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return
    fi

    # Fallback to Core 0
    temp=$(echo "$output" | grep -m1 "Core 0:" | grep -oP '\+\K[0-9]+\.[0-9]+')
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return
    fi
}

# Get temperature for a specific adapter/chip
# Usage: temp=$(sensors_get_temp_by_adapter "nvme-pci-0800")
sensors_get_temp_by_adapter() {
    local adapter="$1"
    sensors_available || return 1

    local output
    # extraction: match adapter block, stop at next adapter (empty line usually) or end
    output=$(echo "${_SENSORS_CACHE:-$(sensors 2>/dev/null)}" | sed -n "/^${adapter}/,/^$/p")

    local temp=""

    # Try Composite first (NVMe)
    temp=$(echo "$output" | grep -m1 "Composite:" | grep -oP '\+\K[0-9]+\.[0-9]+' | head -1)
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return
    fi

    # Try Sensor 1, 2, etc (but validate them!)
    while read -r line; do
        if [[ "$line" =~ \+([0-9]+\.[0-9]+)°C ]]; then
            val="${BASH_REMATCH[1]}"
            if _is_valid_temp "$val"; then
                echo "$val"
                return
            fi
        fi
    done <<<"$(echo "$output" | grep "Sensor")"
}

# Get RAM temperatures (best effort spd detection)
# Returns: "50.2 49.5"
sensors_get_ram_temps() {
    sensors_available || return 1
    local temps=""

    # Look for spd* blocks
    local current_chip=""
    local current_temp=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^(spd[0-9a-z-]+) ]]; then
            current_chip="${BASH_REMATCH[1]}"
            continue
        fi

        # Strict match for temp1 value (avoiding high/crit thresholds)
        # Matches: temp1: +50.2°C ...
        if [[ -n "$current_chip" ]] && [[ "$line" =~ temp1:[[:space:]]*\+([0-9]+\.[0-9]+)°C ]]; then
            val="${BASH_REMATCH[1]}"
            if _is_valid_temp "$val"; then
                temps+="$val "
            fi
            current_chip="" # Reset for next
        fi
    done <<<"${_SENSORS_CACHE:-$(sensors 2>/dev/null)}"

    echo "${temps% }"
}

# Get Network temperatures (best effort r8169 detection)
sensors_get_network_temps() {
    sensors_available || return 1
    local temps=""

    # Look for r8169* blocks
    local current_chip=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^(r8169[0-9a-z_:-]+) ]]; then
            current_chip="${BASH_REMATCH[1]}"
            continue
        fi

        if [[ -n "$current_chip" ]] && [[ "$line" =~ temp1:[[:space:]]*\+([0-9]+\.[0-9]+)°C ]]; then
            val="${BASH_REMATCH[1]}"
            if _is_valid_temp "$val"; then
                temps+="$val "
            fi
            current_chip=""
        fi
    done <<<"${_SENSORS_CACHE:-$(sensors 2>/dev/null)}"

    echo "${temps% }"
}

# Get temperature via Sysfs lookup by PCI ID
# Usage: temp=$(sensors_get_temp_by_pci_id "0000:0d:00.0")
sensors_get_temp_by_pci_id() {
    local pci_id="$1"
    local hwmon_dir="${SYSFS_HWMON_DIR:-/sys/class/hwmon}"

    # Iterate over all hwmon directories
    for dir in "$hwmon_dir"/hwmon*; do
        [[ -d "$dir" ]] || continue

        # Check device symlink
        local dev_link="$dir/device"
        if [[ -L "$dev_link" ]]; then
            # Get target of symlink
            local target
            target=$(readlink "$dev_link")

            # Check if target contains our PCI ID
            if [[ "$target" == *"$pci_id"* ]]; then
                # Found the sensor! Read temp1_input (millidegrees)
                if [[ -f "$dir/temp1_input" ]]; then
                    local millidegrees
                    millidegrees=$(<"$dir/temp1_input")

                    if [[ "$millidegrees" =~ ^[0-9]+$ ]]; then
                        # Convert to degrees (bash arithmetic is integer only, so emulate float)
                        local degrees=$((millidegrees / 1000))
                        local decimal=$(((millidegrees % 1000) / 100)) # 1 decimal place

                        local val="${degrees}.${decimal}"
                        if _is_valid_temp "$val"; then
                            echo "$val"
                            return 0
                        fi
                    fi
                fi
            fi
        fi
    done
    return 1
}

# Legacy functions kept for compatibility but redirected or updated
sensors_get_cpu_temp() { sensors_get_cpu_temp_smart; }
sensors_get_amd_gpu_temp() { sensors_get_amd_edge_temp; }

# AMD GPU edge temperature (stub for compatibility)
# Usage: temp=$(sensors_get_amd_edge_temp)
sensors_get_amd_edge_temp() {
    sensors_available || return 1
    local temp
    temp=$(echo "${_SENSORS_CACHE:-$(sensors 2>/dev/null)}" | grep -m1 "edge:" | grep -oP '\+\K[0-9]+\.[0-9]+')
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return 0
    fi
    return 1
}

# AMD GPU junction temperature (stub for compatibility)
# Usage: temp=$(sensors_get_amd_junction_temp)
sensors_get_amd_junction_temp() {
    sensors_available || return 1
    local temp
    temp=$(echo "${_SENSORS_CACHE:-$(sensors 2>/dev/null)}" | grep -m1 "junction:" | grep -oP '\+\K[0-9]+\.[0-9]+')
    if _is_valid_temp "$temp"; then
        echo "$temp"
        return 0
    fi
    return 1
}

# Get all temperature readings (stub for compatibility)
# Usage: all_temps=$(sensors_get_all_temps)
sensors_get_all_temps() {
    sensors_available || return 1
    local output="${_SENSORS_CACHE:-$(sensors 2>/dev/null)}"

    # Parse sensors output to get: Chip|Adapter|Sensor|Temp
    # Output format required: chip|sensor|temp
    echo "$output" | awk '
        BEGIN { chip=""; adapter="" }
        /^[^ ]/ && !/:/ { 
            # chip line
            chip=$0; 
            gsub(/-.*/, "", chip); 
            next 
        }
        /^Adapter:/ { next }
        /temp[0-9]+:/ || /Sensor [0-9]+:/ || /Core [0-9]+:/ || /Composite:/ || /Packet/ || /Tctl:/ || /Tccd[0-9]+:/ {
            line=$0
            # Extract sensor name
            sensor=$1
            if (sensor ~ /:/) sub(/:/, "", sensor)
            else sensor=$1" "$2
            sub(/:/, "", sensor)

            # Extract temperature
            if (match(line, /\+[0-9]+\.[0-9]+/)) {
                temp=substr(line, RSTART, RLENGTH)
                print chip "|" sensor "|" temp
            }
        }
    '
}

# Get all fan speeds (stub for compatibility)
# Usage: fan_speeds=$(sensors_get_fan_speeds)
sensors_get_fan_speeds() {
    sensors_available || return 1
    echo "${_SENSORS_CACHE:-$(sensors 2>/dev/null)}" | grep -i 'fan' | grep -oP '\d+ RPM' | grep -oP '\d+'
}
