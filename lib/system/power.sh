#!/usr/bin/env bash
# power.sh - Battery/AC adapter abstraction module (acpi + upower)
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_POWER_LOADED:-}" ]] && return 0
_SYSTEM_POWER_LOADED=1

# Check if acpi or upower is installed
# Usage: power_available && echo "power tools available"
power_available() {
    command -v acpi &>/dev/null || command -v upower &>/dev/null
}

# Check if acpi is installed
# Usage: _power_acpi_available && echo "acpi installed"
_power_acpi_available() {
    command -v acpi &>/dev/null
}

# Check if upower is installed
# Usage: _power_upower_available && echo "upower installed"
_power_upower_available() {
    command -v upower &>/dev/null
}

# Check if on AC power
# Usage: power_on_ac && echo "On AC power"
# Returns: 0 if on AC, 1 if on battery or unknown
power_on_ac() {
    power_available || return 1

    # Try acpi first
    if _power_acpi_available; then
        local ac_status
        ac_status=$(acpi -a 2>/dev/null | head -1)
        if [[ "$ac_status" == *"on-line"* ]]; then
            return 0
        elif [[ "$ac_status" == *"off-line"* ]]; then
            return 1
        fi
    fi

    # Try upower
    if _power_upower_available; then
        local line_power
        line_power=$(upower -e 2>/dev/null | grep "line_power")
        if [[ -n "$line_power" ]]; then
            local online
            online=$(upower -i "$line_power" 2>/dev/null | grep "online:" | awk '{print $2}')
            [[ "$online" == "yes" ]] && return 0
            [[ "$online" == "no" ]] && return 1
        fi
    fi

    # Try sysfs as fallback
    if [[ -f /sys/class/power_supply/AC/online ]]; then
        local online
        online=$(cat /sys/class/power_supply/AC/online 2>/dev/null)
        [[ "$online" == "1" ]] && return 0
        [[ "$online" == "0" ]] && return 1
    fi

    return 1
}

# Check if battery is present
# Usage: power_has_battery && echo "Battery present"
# Returns: 0 if battery present, 1 otherwise
power_has_battery() {
    power_available || return 1

    # Try acpi first
    if _power_acpi_available; then
        local battery_info
        battery_info=$(acpi -b 2>/dev/null | head -1)
        [[ -n "$battery_info" && "$battery_info" != *"No support"* ]] && return 0
    fi

    # Try upower
    if _power_upower_available; then
        local battery
        battery=$(upower -e 2>/dev/null | grep "battery")
        [[ -n "$battery" ]] && return 0
    fi

    # Try sysfs
    if ls /sys/class/power_supply/BAT* &>/dev/null; then
        return 0
    fi

    return 1
}

# Get battery charge percentage
# Usage: pct=$(power_get_battery_percent)
# Returns: Battery percentage (0-100) or empty
power_get_battery_percent() {
    power_available || return 1
    power_has_battery || return 1

    # Try acpi first
    if _power_acpi_available; then
        local pct
        pct=$(acpi -b 2>/dev/null | head -1 | grep -oP '[0-9]+(?=%)')
        [[ -n "$pct" ]] && { echo "$pct"; return 0; }
    fi

    # Try upower
    if _power_upower_available; then
        local battery pct
        battery=$(upower -e 2>/dev/null | grep "battery" | head -1)
        if [[ -n "$battery" ]]; then
            pct=$(upower -i "$battery" 2>/dev/null | grep "percentage:" | grep -oP '[0-9]+')
            [[ -n "$pct" ]] && { echo "$pct"; return 0; }
        fi
    fi

    # Try sysfs
    local bat_path
    bat_path=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    if [[ -n "$bat_path" && -f "$bat_path/capacity" ]]; then
        cat "$bat_path/capacity" 2>/dev/null
        return 0
    fi

    return 1
}

# Get battery status
# Usage: status=$(power_get_battery_status)
# Returns: "Charging", "Discharging", "Full", "Not charging", or "Unknown"
power_get_battery_status() {
    power_available || return 1
    power_has_battery || return 1

    # Try acpi first
    if _power_acpi_available; then
        local status
        status=$(acpi -b 2>/dev/null | head -1)
        if [[ "$status" == *"Charging"* ]]; then
            echo "Charging"
            return 0
        elif [[ "$status" == *"Discharging"* ]]; then
            echo "Discharging"
            return 0
        elif [[ "$status" == *"Full"* ]]; then
            echo "Full"
            return 0
        elif [[ "$status" == *"Not charging"* ]]; then
            echo "Not charging"
            return 0
        fi
    fi

    # Try upower
    if _power_upower_available; then
        local battery state
        battery=$(upower -e 2>/dev/null | grep "battery" | head -1)
        if [[ -n "$battery" ]]; then
            state=$(upower -i "$battery" 2>/dev/null | grep "state:" | awk '{print $2}')
            case "$state" in
                charging) echo "Charging"; return 0 ;;
                discharging) echo "Discharging"; return 0 ;;
                fully-charged) echo "Full"; return 0 ;;
                pending-charge) echo "Not charging"; return 0 ;;
            esac
        fi
    fi

    # Try sysfs
    local bat_path
    bat_path=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    if [[ -n "$bat_path" && -f "$bat_path/status" ]]; then
        cat "$bat_path/status" 2>/dev/null
        return 0
    fi

    echo "Unknown"
}

# Get time remaining (charging or discharging)
# Usage: time=$(power_get_battery_time)
# Returns: Time remaining "HH:MM" format or empty if not available
power_get_battery_time() {
    power_available || return 1
    power_has_battery || return 1

    # Try acpi first
    if _power_acpi_available; then
        local time_str
        time_str=$(acpi -b 2>/dev/null | head -1 | grep -oP '[0-9]+:[0-9]+(?::[0-9]+)?')
        if [[ -n "$time_str" ]]; then
            # Return HH:MM format
            echo "$time_str" | cut -d: -f1-2
            return 0
        fi
    fi

    # Try upower
    if _power_upower_available; then
        local battery time_to
        battery=$(upower -e 2>/dev/null | grep "battery" | head -1)
        if [[ -n "$battery" ]]; then
            # Check time to empty or time to full
            time_to=$(upower -i "$battery" 2>/dev/null | grep -E "time to (empty|full):" | head -1 | awk '{print $4, $5}')
            if [[ -n "$time_to" ]]; then
                # Convert "X.Y hours" or "X.Y minutes" to HH:MM
                local value unit
                value=$(echo "$time_to" | awk '{print $1}')
                unit=$(echo "$time_to" | awk '{print $2}')

                if [[ "$unit" == "hours" ]]; then
                    local hours mins
                    hours=$(echo "$value" | cut -d. -f1)
                    local frac
                    frac=$(echo "$value" | cut -d. -f2)
                    mins=$(( (frac * 60) / 10 ))
                    printf "%d:%02d\n" "$hours" "$mins"
                    return 0
                elif [[ "$unit" == "minutes" ]]; then
                    local mins
                    mins=$(echo "$value" | cut -d. -f1)
                    printf "0:%02d\n" "$mins"
                    return 0
                fi
            fi
        fi
    fi

    return 1
}

# Get battery health (current capacity vs design capacity)
# Usage: health=$(power_get_battery_health)
# Returns: Health percentage (0-100) or empty
power_get_battery_health() {
    power_available || return 1
    power_has_battery || return 1

    # Try upower first (more reliable for this)
    if _power_upower_available; then
        local battery energy_full energy_full_design
        battery=$(upower -e 2>/dev/null | grep "battery" | head -1)
        if [[ -n "$battery" ]]; then
            energy_full=$(upower -i "$battery" 2>/dev/null | grep "energy-full:" | awk '{print $2}')
            energy_full_design=$(upower -i "$battery" 2>/dev/null | grep "energy-full-design:" | awk '{print $2}')

            if [[ -n "$energy_full" && -n "$energy_full_design" ]]; then
                # Remove units and calculate percentage
                energy_full=$(echo "$energy_full" | tr -d 'Wh')
                energy_full_design=$(echo "$energy_full_design" | tr -d 'Wh')

                if [[ -n "$energy_full" && -n "$energy_full_design" && "$energy_full_design" != "0" ]]; then
                    local health
                    health=$(awk "BEGIN {printf \"%.0f\", ($energy_full / $energy_full_design) * 100}")
                    echo "$health"
                    return 0
                fi
            fi
        fi
    fi

    # Try sysfs
    local bat_path
    bat_path=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    if [[ -n "$bat_path" ]]; then
        local charge_full charge_full_design
        if [[ -f "$bat_path/charge_full" && -f "$bat_path/charge_full_design" ]]; then
            charge_full=$(cat "$bat_path/charge_full" 2>/dev/null)
            charge_full_design=$(cat "$bat_path/charge_full_design" 2>/dev/null)
        elif [[ -f "$bat_path/energy_full" && -f "$bat_path/energy_full_design" ]]; then
            charge_full=$(cat "$bat_path/energy_full" 2>/dev/null)
            charge_full_design=$(cat "$bat_path/energy_full_design" 2>/dev/null)
        fi

        if [[ -n "$charge_full" && -n "$charge_full_design" && "$charge_full_design" != "0" ]]; then
            local health
            health=$((charge_full * 100 / charge_full_design))
            echo "$health"
            return 0
        fi
    fi

    return 1
}

# Get thermal zone information
# Usage: power_get_thermal_zones
# Returns: Lines of "zone|temp|type"
power_get_thermal_zones() {
    # Try acpi -t first
    if _power_acpi_available; then
        acpi -t 2>/dev/null | while IFS= read -r line; do
            # Parse: "Thermal 0: ok, 45.0 degrees C"
            if [[ "$line" =~ Thermal\ ([0-9]+):\ ([^,]+),\ ([0-9]+)\.[0-9]+\ degrees ]]; then
                local zone="${BASH_REMATCH[1]}"
                local status="${BASH_REMATCH[2]}"
                local temp="${BASH_REMATCH[3]}"
                echo "Thermal $zone|$temp|$status"
            fi
        done
        return 0
    fi

    # Try sysfs thermal zones
    local zone_path
    for zone_path in /sys/class/thermal/thermal_zone*; do
        [[ -d "$zone_path" ]] || continue

        local zone_name temp type
        zone_name=$(basename "$zone_path")

        if [[ -f "$zone_path/temp" ]]; then
            temp=$(cat "$zone_path/temp" 2>/dev/null)
            # Convert millidegrees to degrees
            [[ -n "$temp" ]] && temp=$((temp / 1000))
        fi

        if [[ -f "$zone_path/type" ]]; then
            type=$(cat "$zone_path/type" 2>/dev/null)
        fi

        [[ -z "$temp" ]] && temp="-"
        [[ -z "$type" ]] && type="-"

        echo "${zone_name}|${temp}|${type}"
    done
}

# Get combined battery info
# Usage: info=$(power_get_battery_info)
# Returns: "percent|status|time|health" or empty
power_get_battery_info() {
    power_available || return 1
    power_has_battery || return 1

    local percent status time health

    percent=$(power_get_battery_percent)
    status=$(power_get_battery_status)
    time=$(power_get_battery_time)
    health=$(power_get_battery_health)

    [[ -z "$percent" ]] && percent="-"
    [[ -z "$status" ]] && status="-"
    [[ -z "$time" ]] && time="-"
    [[ -z "$health" ]] && health="-"

    echo "${percent}|${status}|${time}|${health}"
}
