#!/usr/bin/env bash
# hdparm.sh - Disk parameter abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_HDPARM_LOADED:-}" ]] && return 0
_SYSTEM_HDPARM_LOADED=1

# Check if hdparm is installed
# Usage: hdparm_available && echo "hdparm installed"
hdparm_available() {
    command -v hdparm &>/dev/null
}

# Get drive model string
# Usage: model=$(hdparm_get_model "sda")
# Returns: Model string or empty
hdparm_get_model() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    # Add /dev/ prefix if not present
    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo hdparm -I "$device" 2>/dev/null | grep -E "Model Number:" | sed 's/.*Model Number: *//' | sed 's/ *$//'
}

# Get drive serial number
# Usage: serial=$(hdparm_get_serial "sda")
# Returns: Serial number or empty
hdparm_get_serial() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo hdparm -I "$device" 2>/dev/null | grep -E "Serial Number:" | sed 's/.*Serial Number: *//' | sed 's/ *$//'
}

# Get drive firmware version
# Usage: fw=$(hdparm_get_firmware "sda")
# Returns: Firmware version or empty
hdparm_get_firmware() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo hdparm -I "$device" 2>/dev/null | grep -E "Firmware Revision:" | sed 's/.*Firmware Revision: *//' | sed 's/ *$//'
}

# Get drive geometry
# Usage: geometry=$(hdparm_get_geometry "sda")
# Returns: "cylinders heads sectors" or empty
hdparm_get_geometry() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    local cyl heads sects
    local output
    output=$(sudo hdparm -g "$device" 2>/dev/null)

    cyl=$(echo "$output" | grep -oP 'cylinders=\K[0-9]+')
    heads=$(echo "$output" | grep -oP 'heads=\K[0-9]+')
    sects=$(echo "$output" | grep -oP 'sectors=\K[0-9]+')

    if [[ -n "$cyl" && -n "$heads" && -n "$sects" ]]; then
        echo "$cyl $heads $sects"
    fi
}

# Get drive readonly status
# Usage: ro=$(hdparm_get_readonly "sda")
# Returns: 0 (read-write) or 1 (readonly) or empty
hdparm_get_readonly() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    local output
    output=$(sudo hdparm -r "$device" 2>/dev/null | grep "readonly")

    if [[ "$output" == *"= 1"* ]]; then
        echo "1"
    elif [[ "$output" == *"= 0"* ]]; then
        echo "0"
    fi
}

# Check if drive is in standby/sleep mode
# Usage: hdparm_is_sleeping "sda" && echo "Drive sleeping"
# Returns: 0 if sleeping/standby, 1 if active/unknown
hdparm_is_sleeping() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    local output
    output=$(sudo hdparm -C "$device" 2>/dev/null)

    if [[ "$output" == *"standby"* ]] || [[ "$output" == *"sleeping"* ]]; then
        return 0
    fi
    return 1
}

# Get combined drive info
# Usage: info=$(hdparm_get_drive_info "sda")
# Returns: "model|serial|firmware" or empty
hdparm_get_drive_info() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    local output
    output=$(sudo hdparm -I "$device" 2>/dev/null)

    [[ -z "$output" ]] && return 1

    local model serial firmware
    model=$(echo "$output" | grep -E "Model Number:" | sed 's/.*Model Number: *//' | sed 's/ *$//')
    serial=$(echo "$output" | grep -E "Serial Number:" | sed 's/.*Serial Number: *//' | sed 's/ *$//')
    firmware=$(echo "$output" | grep -E "Firmware Revision:" | sed 's/.*Firmware Revision: *//' | sed 's/ *$//')

    # Use "-" for missing fields
    [[ -z "$model" ]] && model="-"
    [[ -z "$serial" ]] && serial="-"
    [[ -z "$firmware" ]] && firmware="-"

    echo "${model}|${serial}|${firmware}"
}

# Get drive transfer mode
# Usage: mode=$(hdparm_get_transfer_mode "sda")
# Returns: Active transfer mode (e.g., "UDMA/133") or empty
hdparm_get_transfer_mode() {
    local device="$1"
    hdparm_available || return 1
    [[ -z "$device" ]] && return 1

    [[ "$device" != /dev/* ]] && device="/dev/$device"

    sudo hdparm -I "$device" 2>/dev/null | grep -E "^\s*\*" | grep -E "UDMA|DMA|PIO" | tail -1 | sed 's/.*\*//' | sed 's/^ *//'
}
