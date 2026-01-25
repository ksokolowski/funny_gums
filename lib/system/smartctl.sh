#!/usr/bin/env bash
# smartctl.sh - Drive health (SMART + NVMe) abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_SMARTCTL_LOADED:-}" ]] && return 0
_SYSTEM_SMARTCTL_LOADED=1

# Check if smartctl is installed
# Usage: smartctl_available && echo "smartctl installed"
smartctl_available() {
    command -v smartctl &>/dev/null
}

# Check if nvme-cli is installed
# Usage: nvme_available && echo "nvme-cli installed"
nvme_available() {
    command -v nvme &>/dev/null
}

# Get drive temperature via SMART
# Usage: temp=$(smartctl_get_temp "sda")
# Returns: Temperature in Celsius or empty
smartctl_get_temp() {
    local device="$1"
    smartctl_available || return 1
    [[ -z "$device" ]] && return 1

    # Add /dev/ prefix if not present
    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo smartctl -A "$device" 2>/dev/null | \
        grep -E "Temperature" | head -1 | awk '{print $10}'
}

# Get NVMe drive temperature
# Usage: temp=$(nvme_get_temp "nvme0n1")
# Returns: Temperature in Celsius or empty
nvme_get_temp() {
    local device="$1"
    nvme_available || return 1
    [[ -z "$device" ]] && return 1

    # Add /dev/ prefix if not present
    [[ "$device" != /dev/* ]] && device="/dev/$device"

    # Strip partition number for NVMe (nvme0n1p1 -> nvme0n1)
    device=$(echo "$device" | sed 's/p[0-9]*$//')

    sudo nvme smart-log "$device" 2>/dev/null | \
        grep -i "temperature" | head -1 | awk '{print $3}'
}

# Unified drive temperature getter (tries SMART then NVMe)
# Usage: temp=$(smartctl_get_drive_temp "sda")
# Returns: Temperature in Celsius or empty
smartctl_get_drive_temp() {
    local device="$1"
    local temp=""

    [[ -z "$device" ]] && return 1

    # Try SMART first
    if smartctl_available; then
        temp=$(smartctl_get_temp "$device")
        [[ -n "$temp" ]] && { echo "$temp"; return 0; }
    fi

    # Try NVMe for nvme devices
    if [[ "$device" == nvme* ]] && nvme_available; then
        temp=$(nvme_get_temp "$device")
        [[ -n "$temp" ]] && { echo "$temp"; return 0; }
    fi

    return 1
}

# Get drive SMART health status
# Usage: health=$(smartctl_get_health "sda")
# Returns: "PASSED", "FAILED", or empty
smartctl_get_health() {
    local device="$1"
    smartctl_available || return 1
    [[ -z "$device" ]] && return 1

    # Add /dev/ prefix if not present
    [[ "$device" != /dev/* ]] && device="/dev/$device"

    local health
    health=$(sudo smartctl -H "$device" 2>/dev/null | grep -E "SMART overall-health" | awk '{print $NF}')
    [[ -n "$health" ]] && echo "$health"
}

# Get NVMe health percentage remaining
# Usage: pct=$(nvme_get_health_pct "nvme0n1")
# Returns: Percentage (0-100) or empty
nvme_get_health_pct() {
    local device="$1"
    nvme_available || return 1
    [[ -z "$device" ]] && return 1

    # Add /dev/ prefix if not present
    [[ "$device" != /dev/* ]] && device="/dev/$device"

    # Strip partition number
    device=$(echo "$device" | sed 's/p[0-9]*$//')

    local pct_used remaining
    pct_used=$(sudo nvme smart-log "$device" 2>/dev/null | \
        grep -i "percentage_used" | awk '{print $3}' | tr -d '%')

    if [[ -n "$pct_used" ]]; then
        remaining=$((100 - pct_used))
        [[ $remaining -lt 0 ]] && remaining=0
        echo "$remaining"
    fi
}

# Get SMART attributes summary
# Usage: smartctl_get_attributes "sda"
# Returns: Lines of "attribute_name|value|threshold|status"
smartctl_get_attributes() {
    local device="$1"
    smartctl_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo smartctl -A "$device" 2>/dev/null | \
        awk '/^  [0-9]/ {print $2"|"$4"|"$6"|"$9}'
}
