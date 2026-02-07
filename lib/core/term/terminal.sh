#!/usr/bin/env bash
# terminal.sh - Terminal capability detection
#
# Detects terminal emoji support level using a 3-tier classification:
#   - full: Full VS16/ZWJ support (Kitty, WezTerm, Ghostty, etc.)
#   - compatible: Displays emojis but has VS16 width issues (VTE/GNOME Terminal)
#   - legacy: Basic terminals with limited emoji support
#
# Usage:
#   source lib/core/terminal.sh
#   detect_terminal_capability
#   if [[ "$TERMINAL_CAPABILITY" == "full" ]]; then
#       echo "Full VS16 emoji support"
#   elif needs_vs16_stripping; then
#       echo "Strip VS16 for proper alignment"
#   fi

[[ -n "${_TERMINAL_SH_LOADED:-}" ]] && return 0
_TERMINAL_SH_LOADED=1

################################################################################
# 3-TIER TERMINAL CLASSIFICATION
################################################################################
#
# Tier       | Terminals                        | VS16 Behavior
# -----------|----------------------------------|--------------------------------
# full       | Kitty, WezTerm, iTerm, Alacritty | Full VS16 support
#            | Ghostty, Windows Terminal        |
# -----------|----------------------------------|--------------------------------
# compatible | VTE-based (GNOME Terminal,       | VS16 stripped for alignment,
#            | Tilix, Terminator)               | colorful emoji fallbacks
# -----------|----------------------------------|--------------------------------
# legacy     | Basic xterm, older terminals,    | Text-based fallbacks
#            | TTY, SSH without TERM forwarding |
################################################################################

# Modern terminals with proper emoji width rendering
readonly MODERN_TERMINALS_PATTERN="kitty|wezterm|iterm|alacritty|ghostty|warp"

# Cached terminal capability (call once at startup for performance)
TERMINAL_CAPABILITY=""
TERMINAL_MODE="" # Backward compat alias

# Check if terminal has full VS16/ZWJ support
# Returns: 0 if full support, 1 otherwise
_is_full_terminal() {
    # Check TERM for known modern terminal types
    [[ "${TERM:-}" =~ (kitty|wezterm|alacritty|ghostty|xterm-256color) ]] &&
        [[ "${TERM_PROGRAM:-}" =~ (iTerm\.app|WezTerm|Alacritty|ghostty|kitty|Apple_Terminal) ]] && return 0

    # Check terminal-specific environment variables
    [[ -n "${KITTY_WINDOW_ID:-}" ]] && return 0
    [[ -n "${WEZTERM_PANE:-}" ]] && return 0
    [[ -n "${ITERM_SESSION_ID:-}" ]] && return 0
    [[ -n "${WT_SESSION:-}" ]] && return 0 # Windows Terminal
    [[ -n "${GHOSTTY_RESOURCES_DIR:-}" ]] && return 0

    return 1
}

# Check if terminal is VTE-based or VS Code (compatible tier)
# These terminals render emojis well but have VS16 width calculation issues
# Returns: 0 if compatible tier, 1 otherwise
_is_compatible_terminal() {
    # GNOME Terminal / VTE
    [[ -n "${VTE_VERSION:-}" ]] && return 0

    # VS Code (xterm.js has issues with some VS16 width calculations)
    [[ "${TERM_PROGRAM:-}" == "vscode" ]] && return 0
    [[ -n "${VSCODE_GIT_ASKPASS_NODE:-}" ]] && return 0
    [[ -n "${TERMINFO_PROGRAM:-}" && "${TERMINFO_PROGRAM:-}" == "vscode" ]] && return 0

    return 1
}

# Detect and cache the terminal capability tier
# Sets TERMINAL_CAPABILITY to "full", "compatible", or "legacy"
# Sets TERMINAL_MODE for backward compatibility ("modern" or "legacy")
detect_terminal_capability() {
    # Allow explicit overrides via environment
    if [[ "${FUNNY_GUMS_TERMINAL_CAPABILITY:-}" =~ ^(full|compatible|legacy)$ ]]; then
        TERMINAL_CAPABILITY="${FUNNY_GUMS_TERMINAL_CAPABILITY}"
    elif [[ "${FUNNY_GUMS_LEGACY_TERMINAL:-}" == "1" ]]; then
        TERMINAL_CAPABILITY="legacy"
    elif [[ "${FUNNY_GUMS_MODERN_TERMINAL:-}" == "1" ]]; then
        TERMINAL_CAPABILITY="full"
    elif _is_full_terminal; then
        TERMINAL_CAPABILITY="full"
    elif _is_compatible_terminal; then
        TERMINAL_CAPABILITY="compatible"
    else
        TERMINAL_CAPABILITY="legacy"
    fi

    # Set backward compat TERMINAL_MODE
    # "modern" = full or compatible (terminals that display emojis well)
    # "legacy" = legacy (terminals that may not display emojis properly)
    if [[ "$TERMINAL_CAPABILITY" == "legacy" ]]; then
        TERMINAL_MODE="legacy"
    else
        TERMINAL_MODE="modern"
    fi

    export TERMINAL_CAPABILITY TERMINAL_MODE
}

# Backward compatibility alias
detect_terminal_mode() {
    detect_terminal_capability
}

# Check if VS16 should be stripped from emojis for proper alignment
# VTE terminals need VS16 stripped because gum calculates width 1 but VTE displays width 2
# Returns: 0 if VS16 should be stripped, 1 otherwise
needs_vs16_stripping() {
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability
    [[ "$TERMINAL_CAPABILITY" == "compatible" ]]
}

# Check if terminal supports ZWJ (Zero Width Joiner) sequences
# ZWJ sequences render as single emoji in modern terminals but
# may display as multiple emojis in legacy terminals
# Returns: 0 if ZWJ supported, 1 otherwise
supports_zwj() {
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability
    [[ "$TERMINAL_CAPABILITY" == "full" ]]
}

# Get terminal capability tier (detects if not already cached)
# Returns: "full", "compatible", or "legacy"
get_terminal_capability() {
    if [[ -z "$TERMINAL_CAPABILITY" ]]; then
        detect_terminal_capability
    fi
    echo "$TERMINAL_CAPABILITY"
}

# Backward compatibility: Check if terminal is "modern" (displays emojis well)
# Returns: 0 if modern (full or compatible), 1 if legacy
is_modern_terminal() {
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability
    [[ "$TERMINAL_CAPABILITY" != "legacy" ]]
}

# Get terminal mode (backward compatibility)
# Returns: "modern" or "legacy"
get_terminal_mode() {
    if [[ -z "$TERMINAL_MODE" ]]; then
        detect_terminal_capability
    fi
    echo "$TERMINAL_MODE"
}
