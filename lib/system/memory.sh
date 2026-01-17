#!/usr/bin/env bash
# memory.sh - Memory and swap monitoring functions
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_MEMORY_LOADED:-}" ]] && return 0
_SYSTEM_MEMORY_LOADED=1

# Get memory usage
# Usage: read -r used_kb total_kb percent <<< "$(get_memory_usage_live)"
# Returns: "used_kb total_kb percent"
get_memory_usage_live() {
    local total_kb available_kb used_kb percent

    total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

    used_kb=$((total_kb - available_kb))

    if [[ $total_kb -gt 0 ]]; then
        percent=$((used_kb * 100 / total_kb))
    else
        percent=0
    fi

    echo "$used_kb $total_kb $percent"
}

# Get swap usage
# Usage: read -r used_kb total_kb percent <<< "$(get_swap_usage_live)"
# Returns: "used_kb total_kb percent" (all 0 if no swap)
get_swap_usage_live() {
    local total_kb free_kb used_kb percent

    total_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    free_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)

    if [[ -z "$total_kb" ]] || [[ "$total_kb" -eq 0 ]]; then
        echo "0 0 0"
        return
    fi

    used_kb=$((total_kb - free_kb))
    percent=$((used_kb * 100 / total_kb))

    echo "$used_kb $total_kb $percent"
}
