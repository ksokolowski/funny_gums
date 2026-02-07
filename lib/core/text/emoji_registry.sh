#!/usr/bin/env bash
# emoji_registry.sh - Unified emoji registry with automatic fallbacks
#
# Provides a registry of emojis with automatic degradation based on terminal
# capability. VS16 emojis have colorful fallbacks for VTE terminals and
# text fallbacks for legacy terminals.
#
# Usage:
#   source lib/core/emoji_registry.sh
#   detect_terminal_capability  # Or detect_terminal_mode for compat
#
#   # Get appropriate emoji for current terminal
#   warning_icon=$(emoji "WARNING")
#
#   # Or access exported variables (populated at source time)
#   echo "$EMOJI_WARNING Something went wrong"

[[ -n "${_EMOJI_REGISTRY_SH_LOADED:-}" ]] && return 0
_EMOJI_REGISTRY_SH_LOADED=1

_REGISTRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_REGISTRY_DIR/../term/terminal.sh"

################################################################################
# EMOJI REGISTRY
# Format: "name:primary:compatible:legacy"
#   - name: Variable name suffix (e.g., WARNING -> EMOJI_WARNING)
#   - primary: Full VS16 emoji for "full" terminals
#   - compatible: Colorful fallback (no VS16) for VTE terminals
#   - legacy: Text-based fallback for legacy terminals
#
# Using hex encoding for VS16 emojis to avoid git encoding issues.
# VS16 (U+FE0F) = \xef\xb8\x8f
################################################################################

# VS16 bytes for building emojis
_VS16=$'\xef\xb8\x8f'

# Build registry programmatically to handle VS16 encoding consistently
declare -gA _EMOJI_REGISTRY=()

# Helper to add registry entry
_add_emoji() {
    local name="$1"
    local primary="$2"
    local compatible="$3"
    local legacy="$4"
    _EMOJI_REGISTRY["${name}_full"]="$primary"
    _EMOJI_REGISTRY["${name}_compatible"]="$compatible"
    _EMOJI_REGISTRY["${name}_legacy"]="$legacy"
}

################################################################################
# VS16 EMOJI DEFINITIONS WITH SEMANTIC FALLBACKS
################################################################################

# Status indicators with VS16
_add_emoji "WARNING" $'\xe2\x9a\xa0\xef\xb8\x8f' $'\xf0\x9f\x9f\xa1' "[!]" # ⚠️ -> 🟡 -> [!]
_add_emoji "PAUSED" $'\xe2\x8f\xb8\xef\xb8\x8f' $'\xf0\x9f\x9f\xa0' "||"   # ⏸️ -> 🟠 -> ||

# Hardware
_add_emoji "CPU" $'\xe2\x9a\x99\xef\xb8\x8f' $'\xf0\x9f\x94\xa7' "[*]"         # ⚙️ -> 🔧 -> [*]
_add_emoji "MEMORY" $'\xf0\x9f\xa7\xa0' $'\xf0\x9f\xa7\xa0' "[M]"              # 🧠 -> 🧠 -> [M]
_add_emoji "DISK" $'\xf0\x9f\x92\xbe' $'\xf0\x9f\x92\xbe' "[D]"                # 💾 -> 💾 -> [D]
_add_emoji "DISK_COL" $'\xf0\x9f\x92\xbf' $'\xf0\x9f\x92\xbf' "[O]"            # 💿 -> 💿 -> [O]
_add_emoji "DISK_HEAD" $'\xf0\x9f\x92\xbf' $'\xf0\x9f\x92\xbf' "[O]"           # 💿 -> 💿 -> [O] (Header)
_add_emoji "GPU" $'\xf0\x9f\x8e\xae' $'\xf0\x9f\x8e\xae' "[G]"                 # 🎮 -> 🎮 -> [G]
_add_emoji "TEMP" $'\xf0\x9f\x8c\xa1\xef\xb8\x8f' $'\xf0\x9f\x94\xa5' "[T]"    # 🌡️ -> 🔥 -> [T]
_add_emoji "SERVER" $'\xf0\x9f\x96\xa5\xef\xb8\x8f' $'\xf0\x9f\x92\xbb' "[S]"  # 🖥️ -> 💻 -> [S]
_add_emoji "PRINTER" $'\xf0\x9f\x96\xa8\xef\xb8\x8f' $'\xf0\x9f\x93\x84' "[P]" # 🖨️ -> 📄 -> [P]
_add_emoji "POWER" $'\xf0\x9f\x94\x8b' $'\xf0\x9f\x94\x8b' "[B]"               # 🔋 -> 🔋 -> [B]
_add_emoji "NETWORK" $'\xf0\x9f\x8c\x90' $'\xf0\x9f\x8c\x90' "[N]"             # 🌐 -> 🌐 -> [N]
_add_emoji "SPEAKER" $'\xf0\x9f\x94\x8a' $'\xf0\x9f\x94\x8a' "[A]"             # 🔊 -> 🔊 -> [A]

# Actions with VS16
_add_emoji "REMOVE" $'\xf0\x9f\x97\x91\xef\xb8\x8f' $'\xe2\x9d\x8c' "[X]" # 🗑️ -> ❌ -> [X]
_add_emoji "SCISSORS" $'\xe2\x9c\x82\xef\xb8\x8f' $'\xe2\x9c\x82' "[/]"   # ✂️ -> ✂ -> [/]

# Categories with VS16
_add_emoji "DATABASE" $'\xf0\x9f\x97\x84\xef\xb8\x8f' $'\xf0\x9f\x93\xa6' "[D]" # 🗄️ -> 📦 -> [D]
_add_emoji "CLOUD" $'\xe2\x98\x81\xef\xb8\x8f' $'\xf0\x9f\x92\xad' "[C]"        # ☁️ -> 💭 -> [C]
_add_emoji "TAG" $'\xf0\x9f\x8f\xb7\xef\xb8\x8f' $'\xf0\x9f\x93\x8c' "[#]"      # 🏷️ -> 📌 -> [#]

# Nature with VS16
_add_emoji "SUN" $'\xe2\x98\x80\xef\xb8\x8f' $'\xf0\x9f\x9f\xa1' "(o)"       # ☀️ -> 🟡 -> (o)
_add_emoji "SNOWFLAKE" $'\xe2\x9d\x84\xef\xb8\x8f' $'\xf0\x9f\x92\x8e' "[*]" # ❄️ -> 💎 -> [*]

# Hearts with VS16
_add_emoji "HEART_RED" $'\xe2\x9d\xa4\xef\xb8\x8f' $'\xf0\x9f\x92\x97' "<3" # ❤️ -> 💗 -> <3

# Media controls with VS16
_add_emoji "PLAY_VS" $'\xe2\x96\xb6\xef\xb8\x8f' $'\xf0\x9f\x94\xb5' "[>]"   # ▶️ -> 🔵 -> [>]
_add_emoji "STOP_VS" $'\xe2\x8f\xb9\xef\xb8\x8f' $'\xf0\x9f\x94\xb4' "[.]"   # ⏹️ -> 🔴 -> [.]
_add_emoji "RECORD_VS" $'\xe2\x8f\xba\xef\xb8\x8f' $'\xf0\x9f\x94\xb4' "(o)" # ⏺️ -> 🔴 -> (o)
_add_emoji "EJECT_VS" $'\xe2\x8f\x8f\xef\xb8\x8f' $'\xf0\x9f\x94\xbc' "[^]"  # ⏏️ -> 🔼 -> [^]
_add_emoji "NEXT_VS" $'\xe2\x8f\xad\xef\xb8\x8f' $'\xe2\x8f\xa9' ">>"        # ⏭️ -> ⏩ -> >>
_add_emoji "PREV_VS" $'\xe2\x8f\xae\xef\xb8\x8f' $'\xe2\x8f\xaa' "<<"        # ⏮️ -> ⏪ -> <<

# Input devices with VS16
_add_emoji "KEYBOARD_VS" $'\xe2\x8c\xa8\xef\xb8\x8f' $'\xf0\x9f\x92\xbb' "[K]"     # ⌨️ -> 💻 -> [K]
_add_emoji "MOUSE_VS" $'\xf0\x9f\x96\xb1\xef\xb8\x8f' $'\xf0\x9f\x96\xb1' "[M]"    # 🖱️ -> 🖱 -> [M]
_add_emoji "JOYSTICK_VS" $'\xf0\x9f\x95\xb9\xef\xb8\x8f' $'\xf0\x9f\x8e\xae' "[J]" # 🕹️ -> 🎮 -> [J]

# Misc with VS16
_add_emoji "UMBRELLA_VS" $'\xe2\x98\x82\xef\xb8\x8f' $'\xf0\x9f\x8c\xa7' "[U]"   # ☂️ -> 🌧 -> [U]
_add_emoji "SHIELD_VS" $'\xf0\x9f\x9b\xa1\xef\xb8\x8f' $'\xf0\x9f\x9b\xa1' "[#]" # 🛡️ -> 🛡 -> [#]
_add_emoji "SWORDS_VS" $'\xe2\x9a\x94\xef\xb8\x8f' $'\xe2\x9a\x94' "[X]"         # ⚔️ -> ⚔ -> [X]
_add_emoji "ALEMBIC_VS" $'\xe2\x9a\x97\xef\xb8\x8f' $'\xf0\x9f\xa7\xaa' "[A]"    # ⚗️ -> 🧪 -> [A]
_add_emoji "RECYCLE_VS" $'\xe2\x99\xbb\xef\xb8\x8f' $'\xe2\x99\xbb' "[R]"        # ♻️ -> ♻ -> [R]

# New additions
_add_emoji "SERVICE" $'\xe2\x9a\xa1\xef\xb8\x8f' $'\xe2\x9a\xa1' "[L]"         # ⚡️ -> ⚡ -> [L]
_add_emoji "RGB" $'\xf0\x9f\x8c\x88\xef\xb8\x8f' $'\xf0\x9f\x8c\x88' "(=)"     # 🌈 -> 🌈 -> (=)
_add_emoji "PACKAGE" $'\xf0\x9f\x93\xa6\xef\xb8\x8f' $'\xf0\x9f\x93\xa6' "[P]" # 📦 -> 📦 -> [P]
_add_emoji "ALERT" $'\xf0\x9f\x9a\xa8\xef\xb8\x8f' $'\xf0\x9f\x9a\xa8' "[!]"   # 🚨 -> 🚨 -> [!]

################################################################################
# EMOJI ACCESS FUNCTION
################################################################################

# Get the appropriate emoji for the current terminal capability
# Usage: emoji "NAME"
# Returns: Emoji string appropriate for current terminal
#
# Examples:
#   emoji "WARNING"   # Returns ⚠️, 🟡, or [!] based on terminal
#   emoji "CPU"       # Returns ⚙️, 🔧, or [*] based on terminal
emoji() {
    local name="$1"
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability

    case "$TERMINAL_CAPABILITY" in
    full)
        echo "${_EMOJI_REGISTRY[${name}_full]:-}"
        ;;
    compatible)
        echo "${_EMOJI_REGISTRY[${name}_compatible]:-}"
        ;;
    legacy | *)
        echo "${_EMOJI_REGISTRY[${name}_legacy]:-}"
        ;;
    esac
}

# Get specific emoji variant regardless of terminal capability
# Usage: emoji_variant "NAME" "full|compatible|legacy"
emoji_variant() {
    local name="$1"
    local variant="$2"
    echo "${_EMOJI_REGISTRY[${name}_${variant}]:-}"
}

# Check if an emoji is registered
# Usage: is_registered_emoji "NAME"
# Returns: 0 if registered, 1 otherwise
is_registered_emoji() {
    local name="$1"
    [[ -n "${_EMOJI_REGISTRY[${name}_full]:-}" ]]
}

################################################################################
# VARIABLE EXPORT FOR BACKWARD COMPATIBILITY
################################################################################

# Export VS16 emoji variables based on terminal capability
# Called automatically when this file is sourced
# Re-call after changing TERMINAL_CAPABILITY to update variables
_export_emoji_vars() {
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability

    local name variant
    local -a registered_names=(
        WARNING PAUSED CPU MEMORY DISK DISK_COL DISK_HEAD GPU TEMP SERVER
        PRINTER POWER NETWORK SPEAKER REMOVE SCISSORS
        DATABASE CLOUD TAG SUN SNOWFLAKE HEART_RED
        PLAY_VS STOP_VS RECORD_VS EJECT_VS NEXT_VS PREV_VS
        KEYBOARD_VS MOUSE_VS JOYSTICK_VS
        UMBRELLA_VS SHIELD_VS SWORDS_VS ALEMBIC_VS RECYCLE_VS
        SERVICE RGB PACKAGE ALERT
    )

    case "$TERMINAL_CAPABILITY" in
    full) variant="full" ;;
    compatible) variant="compatible" ;;
    *) variant="legacy" ;;
    esac

    for name in "${registered_names[@]}"; do
        local var_name="EMOJI_${name}"
        local value="${_EMOJI_REGISTRY[${name}_${variant}]:-}"
        if [[ -n "$value" ]]; then
            declare -g "$var_name"="$value"
        fi
    done
}

################################################################################
# STRIP VS16 UTILITY
################################################################################

# Strip VS16 from a string (used for compatible terminals)
# Usage: strip_vs16 "text with ⚙️"
# Returns: text with VS16 bytes removed
strip_vs16() {
    local text="$1"
    # VS16 in UTF-8 is \xef\xb8\x8f (3 bytes)
    printf '%s' "${text//$_VS16/}"
}

################################################################################
# AUTO-INITIALIZATION
################################################################################

# Detect terminal capability on source if not already done
if [[ -z "$TERMINAL_CAPABILITY" ]]; then
    detect_terminal_capability
fi

# Export emoji variables based on detected capability
_export_emoji_vars
