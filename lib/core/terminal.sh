#!/usr/bin/env bash
# terminal.sh - Terminal capability detection
#
# Detects whether the terminal supports modern emoji rendering (proper VS16 width)
# or requires legacy fallback handling.
#
# Usage:
#   source lib/core/terminal.sh
#   detect_terminal_mode
#   if [[ "$TERMINAL_MODE" == "modern" ]]; then
#       echo "Terminal supports proper emoji widths"
#   fi

[[ -n "${_TERMINAL_SH_LOADED:-}" ]] && return 0
_TERMINAL_SH_LOADED=1

# Modern terminals with proper emoji width rendering
# These terminals correctly handle VS16 (Variation Selector 16) emojis
# and render them at width 2
readonly MODERN_TERMINALS_PATTERN="kitty|wezterm|iterm|alacritty|ghostty|warp"

# Check if current terminal is modern (supports proper emoji width)
# Returns: 0 if modern, 1 if legacy
is_modern_terminal() {
    # Check TERM for known modern terminal types
    [[ "${TERM:-}" =~ (kitty|wezterm|alacritty) ]] && return 0

    # Check TERM_PROGRAM (set by many GUI terminals)
    case "${TERM_PROGRAM:-}" in
        iTerm.app|WezTerm|Alacritty|ghostty|kitty) return 0 ;;
    esac

    # Check terminal-specific environment variables
    [[ -n "${KITTY_WINDOW_ID:-}" ]] && return 0
    [[ -n "${WEZTERM_PANE:-}" ]] && return 0
    [[ -n "${ITERM_SESSION_ID:-}" ]] && return 0
    [[ -n "${WT_SESSION:-}" ]] && return 0      # Windows Terminal
    [[ -n "${GHOSTTY_RESOURCES_DIR:-}" ]] && return 0

    # Check for GNOME Terminal (modern versions handle VS16 well)
    [[ "${VTE_VERSION:-0}" -ge 6003 ]] && return 0

    # Explicit override via environment variable
    [[ "${FUNNY_GUMS_MODERN_TERMINAL:-}" == "1" ]] && return 0

    return 1
}

# Cached terminal mode (call once at startup for performance)
TERMINAL_MODE=""

# Detect and cache the terminal mode
# Sets TERMINAL_MODE to "modern" or "legacy"
detect_terminal_mode() {
    # Allow explicit legacy override
    if [[ "${FUNNY_GUMS_LEGACY_TERMINAL:-}" == "1" ]]; then
        TERMINAL_MODE="legacy"
    elif is_modern_terminal; then
        TERMINAL_MODE="modern"
    else
        TERMINAL_MODE="legacy"
    fi
    export TERMINAL_MODE
}

# Get terminal mode (detects if not already cached)
# Returns: "modern" or "legacy"
get_terminal_mode() {
    if [[ -z "$TERMINAL_MODE" ]]; then
        detect_terminal_mode
    fi
    echo "$TERMINAL_MODE"
}
