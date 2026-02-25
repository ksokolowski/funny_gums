#!/usr/bin/env bash
# base.sh - Common utility functions for system modules
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_BASE_LOADED:-}" ]] && return 0
_SYSTEM_BASE_LOADED=1

# Format bytes to human readable
# Usage: human_size=$(format_bytes 1234567890)
# Returns: "1.2 GiB"
format_bytes() {
    local bytes="$1"
    local units=("B" "KiB" "MiB" "GiB" "TiB")
    local unit=0
    local value=$bytes

    while [[ $value -ge 1024 ]] && [[ $unit -lt 4 ]]; do
        value=$((value / 1024))
        ((unit++))
    done

    # For more precision with large values, use bc if available
    if command -v bc &>/dev/null && [[ $bytes -ge 1073741824 ]]; then
        local precise
        case $unit in
        3) precise=$(echo "scale=1; $bytes / 1073741824" | bc) ;;    # GiB
        4) precise=$(echo "scale=2; $bytes / 1099511627776" | bc) ;; # TiB
        *) precise=$value ;;
        esac
        # Normalize: strip trailing zeros after decimal point (e.g., "2.0" -> "2")
        precise="${precise%%\.0}"
        echo "$precise ${units[$unit]}"
    else
        echo "$value ${units[$unit]}"
    fi
}

# Format KB to human readable
# Usage: human_size=$(format_kb 1234567)
format_kb() {
    local kb="$1"
    format_bytes "$((kb * 1024))"
}
