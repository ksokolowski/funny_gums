#!/usr/bin/env bash
# spinner.sh - Spinner animation functions
# Source this file for animated spinner utilities

# Prevent multiple sourcing
[[ -n "${_SPINNER_SH_LOADED:-}" ]] && return 0
_SPINNER_SH_LOADED=1

# Default spinner frames (RGB color cycle)
SPINNER_FRAMES=("🔴" "🟠" "🟡" "🟢" "🔵" "🟣")

# Alternative spinner sets
SPINNER_DOTS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_CIRCLE=("◐" "◓" "◑" "◒")
SPINNER_BRAILLE=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
SPINNER_GLOBE=("🌍" "🌎" "🌏")
SPINNER_MOON=("🌑" "🌒" "🌓" "🌔" "🌕" "🌖" "🌗" "🌘")
SPINNER_CLOCK=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
SPINNER_ARROWS=("⬆️ " "↗️ " "➡️ " "↘️ " "⬇️ " "↙️ " "⬅️ " "↖️ ")
SPINNER_BOUNCE=("⠁" "⠂" "⠄" "⠂")

# Current spinner state
SPINNER_IDX=0

# Set spinner type
# Usage: spinner_set DOTS|CIRCLE|BRAILLE|GLOBE|MOON|CLOCK|ARROWS|BOUNCE|RGB
spinner_set() {
    local type="${1:-RGB}"
    case "$type" in
    DOTS) SPINNER_FRAMES=("${SPINNER_DOTS[@]}") ;;
    CIRCLE) SPINNER_FRAMES=("${SPINNER_CIRCLE[@]}") ;;
    BRAILLE) SPINNER_FRAMES=("${SPINNER_BRAILLE[@]}") ;;
    GLOBE) SPINNER_FRAMES=("${SPINNER_GLOBE[@]}") ;;
    MOON) SPINNER_FRAMES=("${SPINNER_MOON[@]}") ;;
    CLOCK) SPINNER_FRAMES=("${SPINNER_CLOCK[@]}") ;;
    ARROWS) SPINNER_FRAMES=("${SPINNER_ARROWS[@]}") ;;
    BOUNCE) SPINNER_FRAMES=("${SPINNER_BOUNCE[@]}") ;;
    RGB) SPINNER_FRAMES=("🔴" "🟠" "🟡" "🟢" "🔵" "🟣") ;;
    *) SPINNER_FRAMES=("$@") ;; # Custom frames
    esac
}

# Set custom spinner frames
# Usage: spinner_custom "frame1" "frame2" "frame3" ...
spinner_custom() {
    SPINNER_FRAMES=("$@")
}

# Reset spinner index
spinner_reset() {
    SPINNER_IDX=0
}

# Get current spinner frame
spinner_frame() {
    local frame_idx=$((SPINNER_IDX % ${#SPINNER_FRAMES[@]}))
    echo "${SPINNER_FRAMES[$frame_idx]}"
}

# Get current spinner frame (sets variable, no subshell)
# Usage: spinner_frame_ref var_name
spinner_frame_ref() {
    local frame_idx=$((SPINNER_IDX % ${#SPINNER_FRAMES[@]}))
    printf -v "$1" '%s' "${SPINNER_FRAMES[$frame_idx]}"
}

# Advance spinner to next frame
spinner_next() {
    SPINNER_IDX=$((SPINNER_IDX + 1))
}

# Get frame and advance (convenience function)
spinner_tick() {
    spinner_frame
    spinner_next
}

# Get frame and advance (sets variable)
# Usage: spinner_tick_ref var_name
spinner_tick_ref() {
    spinner_frame_ref "$1"
    spinner_next
}
