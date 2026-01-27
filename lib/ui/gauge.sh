#!/usr/bin/env bash
# gauge.sh - Progress bar and gauge visualization functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_UI_GAUGE_LOADED:-}" ]] && return 0
_UI_GAUGE_LOADED=1

# Source colors for gauge coloring
_UI_GAUGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_GAUGE_DIR/../core/colors.sh"

#---------------------------------------
# Internal helpers (DRY)
#---------------------------------------

# Build a progress bar string of filled/empty characters
# Usage: bar=$(_ui_build_bar <filled_count> <empty_count>)
_ui_build_bar() {
    local filled=$1 empty=$2 bar="" i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

# Get threshold-based color (green/yellow/red)
# Usage: color=$(_ui_threshold_color <value> [warn] [crit])
_ui_threshold_color() {
    local value="${1%.*}" warn="${2:-70}" crit="${3:-90}" # Truncate float to int
    warn="${warn%.*}"; crit="${crit%.*}"

    if ((value >= crit)); then
        echo "$NEON_RED"
    elif ((value >= warn)); then
        echo "$NEON_YELLOW"
    else
        echo "$NEON_GREEN"
    fi
}

# Clamp a value to 0-100 range
# Usage: percent=$(_ui_clamp_percent <value>)
_ui_clamp_percent() {
    local val="${1%.*}" # Truncate float
    ((val < 0)) && val=0
    ((val > 100)) && val=100
    echo "$val"
}

# Normalize current/max values for gauge calculations
# Usage: read -r current max percent <<< "$(_ui_normalize_gauge <current> <max>)"
_ui_normalize_gauge() {
    local current="${1%.*}" max="${2%.*}" # Truncate floats
    ((max <= 0)) && max=1
    ((current > max)) && current=$max
    ((current < 0)) && current=0
    local percent=$((current * 100 / max))
    echo "$current $max $percent"
}

#---------------------------------------
# Public gauge functions
#---------------------------------------

# Basic horizontal progress bar
# Usage: ui_gauge <current> <max> [width] [label]
# Example: ui_gauge 62 100 20 "RAM"
# Output: RAM      [████████████░░░░░░░░] 62%
ui_gauge() {
    local current="$1" max="$2" width="${3:-20}" label="${4:-}"
    local percent

    read -r current max percent <<< "$(_ui_normalize_gauge "$current" "$max")"

    local filled=$((current * width / max))
    local bar
    bar=$(_ui_build_bar "$filled" $((width - filled)))

    if [[ -n "$label" ]]; then
        printf "%-8s [%s] %3d%%" "$label" "$bar" "$percent"
    else
        printf "[%s] %3d%%" "$bar" "$percent"
    fi
}

# Color-coded progress bar with thresholds
# Usage: ui_gauge_colored <current> <max> [width] [label] [warn_threshold] [crit_threshold]
# Colors: green (< warn), yellow (warn-crit), red (>= crit)
ui_gauge_colored() {
    local current="$1" max="$2" width="${3:-20}" label="${4:-}"
    local warn="${5:-70}" crit="${6:-90}"
    local percent color

    read -r current max percent <<< "$(_ui_normalize_gauge "$current" "$max")"
    color=$(_ui_threshold_color "$percent" "$warn" "$crit")

    local filled=$((current * width / max))
    local bar
    bar=$(_ui_build_bar "$filled" $((width - filled)))

    if [[ -n "$label" ]]; then
        printf "%s%-8s [%s] %3d%%%s" "$color" "$label" "$bar" "$percent" "$RESET"
    else
        printf "%s[%s] %3d%%%s" "$color" "$bar" "$percent" "$RESET"
    fi
}

# Temperature display with status coloring
# Usage: ui_temp_gauge <temp_celsius> [warn] [crit] [label]
# Example: ui_temp_gauge 65 70 85 "CPU"
ui_temp_gauge() {
    local temp="$1" warn="${2:-70}" crit="${3:-85}" label="${4:-Temp}"

    # Extract numeric value (handle "65.0" or "65")
    local temp_int="${temp%.*}"
    [[ -z "$temp_int" ]] && temp_int=0

    local color
    color=$(_ui_threshold_color "$temp_int" "$warn" "$crit")

    printf "%s%-8s %s°C%s" "$color" "$label" "$temp" "$RESET"
}

# Single-character vertical bar using Unicode blocks
# Usage: ui_vbar <percent>
# Output: Single character (▁▂▃▄▅▆▇█) representing level
ui_vbar() {
    local percent
    percent=$(_ui_clamp_percent "$1")
    local blocks=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

    local idx=$((percent * 7 / 100))
    ((percent == 0)) && idx=0

    echo "${blocks[$idx]}"
}

# Colored status indicator dot
# Usage: ui_status "OK"|"WARN"|"CRIT"|"UNKNOWN"
# Output: Colored dot character
ui_status() {
    case "${1^^}" in
        OK|GOOD|NORMAL|HEALTHY)   printf "%s●%s" "$NEON_GREEN" "$RESET" ;;
        WARN|WARNING|MEDIUM)      printf "%s●%s" "$NEON_YELLOW" "$RESET" ;;
        CRIT|CRITICAL|ERROR|HIGH|DANGER) printf "%s●%s" "$NEON_RED" "$RESET" ;;
        *)                        printf "%s●%s" "$BRIGHT_BLACK" "$RESET" ;;
    esac
}

# Mini horizontal bar for sidebar (compact, no label)
# Usage: ui_minibar <percent> [width]
ui_minibar() {
    local percent width="${2:-5}"
    percent=$(_ui_clamp_percent "$1")

    local filled=$((percent * width / 100))
    _ui_build_bar "$filled" $((width - filled))
}

# Colored mini bar for sidebar
# Usage: ui_minibar_colored <percent> [width] [warn] [crit]
ui_minibar_colored() {
    local percent width="${2:-5}" warn="${3:-70}" crit="${4:-90}"
    percent=$(_ui_clamp_percent "$1")

    local color
    color=$(_ui_threshold_color "$percent" "$warn" "$crit")

    local filled=$((percent * width / 100))
    local bar
    bar=$(_ui_build_bar "$filled" $((width - filled)))

    printf "%s%s%s" "$color" "$bar" "$RESET"
}
