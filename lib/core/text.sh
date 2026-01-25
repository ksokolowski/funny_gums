#!/usr/bin/env bash
# text.sh - Visual width calculation for emoji-aware text processing
#
# Provides functions for calculating the visual (display) width of strings
# containing emojis, VS16 sequences, ZWJ sequences, and wide characters.
# Uses lookup tables for O(1) emoji width queries.
#
# Usage:
#   source lib/core/text.sh
#   visual_width "Hello ⚙️ World"  # Returns: 14
#   pad_visual "Hi" 10             # Returns: "Hi        "

[[ -n "${_TEXT_SH_LOADED:-}" ]] && return 0
_TEXT_SH_LOADED=1

_TEXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_TEXT_DIR/terminal.sh"
source "$_TEXT_DIR/emoji_data.sh"

################################################################################
# ANSI STRIPPING
################################################################################

# Strip ANSI escape sequences from text
# Usage: strip_ansi "colored text"
# Returns: text without ANSI codes
strip_ansi() {
    local text="$1"
    # Remove all ANSI escape sequences (CSI sequences)
    # shellcheck disable=SC2001
    echo "$text" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

################################################################################
# WIDE CHARACTER DETECTION
################################################################################

# Check if a codepoint is a wide character (CJK, fullwidth forms)
# Usage: _is_wide_char codepoint
# Returns: 0 if wide (2 cells), 1 if not wide (1 cell)
_is_wide_char() {
    local cp=$1

    # Hangul Jamo
    ((cp >= 0x1100 && cp <= 0x115F)) && return 0
    ((cp >= 0x2329 && cp <= 0x232A)) && return 0

    # CJK ranges
    ((cp >= 0x2E80 && cp <= 0x2EFF)) && return 0   # CJK Radicals
    ((cp >= 0x2F00 && cp <= 0x2FDF)) && return 0   # Kangxi Radicals
    ((cp >= 0x2FF0 && cp <= 0x2FFF)) && return 0   # Ideographic Description
    ((cp >= 0x3000 && cp <= 0x303E)) && return 0   # CJK Symbols
    ((cp >= 0x3041 && cp <= 0x3096)) && return 0   # Hiragana
    ((cp >= 0x30A1 && cp <= 0x30FA)) && return 0   # Katakana
    ((cp >= 0x3105 && cp <= 0x312D)) && return 0   # Bopomofo
    ((cp >= 0x3131 && cp <= 0x318E)) && return 0   # Hangul Compatibility
    ((cp >= 0x3190 && cp <= 0x31BA)) && return 0   # Kanbun
    ((cp >= 0x31C0 && cp <= 0x31E3)) && return 0   # CJK Strokes
    ((cp >= 0x31F0 && cp <= 0x31FF)) && return 0   # Katakana Extension
    ((cp >= 0x3200 && cp <= 0x321E)) && return 0   # Enclosed CJK
    ((cp >= 0x3220 && cp <= 0x3247)) && return 0   # Enclosed CJK
    ((cp >= 0x3250 && cp <= 0x32FE)) && return 0   # Enclosed CJK
    ((cp >= 0x3300 && cp <= 0x4DBF)) && return 0   # CJK Compatibility + Extensions
    ((cp >= 0x4E00 && cp <= 0x9FFF)) && return 0   # CJK Unified Ideographs

    # Hangul Syllables
    ((cp >= 0xAC00 && cp <= 0xD7A3)) && return 0

    # CJK Compatibility Ideographs
    ((cp >= 0xF900 && cp <= 0xFAFF)) && return 0

    # Vertical forms
    ((cp >= 0xFE10 && cp <= 0xFE1F)) && return 0

    # Fullwidth forms
    ((cp >= 0xFF00 && cp <= 0xFF60)) && return 0
    ((cp >= 0xFFE0 && cp <= 0xFFE6)) && return 0

    # CJK Extensions (Plane 2)
    ((cp >= 0x20000 && cp <= 0x2FFFF)) && return 0

    # CJK Extensions (Plane 3)
    ((cp >= 0x30000 && cp <= 0x3FFFF)) && return 0

    return 1
}

################################################################################
# VISUAL WIDTH CALCULATION
################################################################################

# Calculate visual width of a string (display columns)
# Handles ANSI codes, VS16/VS15, ZWJ, wide chars, and emoji
# Usage: visual_width "string" [modern|legacy]
# Returns: integer width in terminal columns
visual_width() {
    local text="$1"
    local mode="${2:-${TERMINAL_MODE:-modern}}"

    # Empty string has width 0
    [[ -z "$text" ]] && echo 0 && return

    # Strip ANSI codes first
    text=$(strip_ansi "$text")

    # Fast path: pure ASCII printable characters
    # Note: [[:ascii:]] doesn't work reliably with UTF-8 multi-byte chars
    # Instead, check if string length in bytes equals character count
    local byte_len
    byte_len=$(printf '%s' "$text" | wc -c)
    if [[ "$byte_len" -eq "${#text}" ]] && [[ "$text" =~ ^[[:print:]]*$ ]]; then
        echo "${#text}"
        return
    fi

    local width=0
    local i=0
    local len=${#text}

    while ((i < len)); do
        local char="${text:i:1}"

        # Skip zero-width characters
        if [[ "$char" == "$VS16" ]] || [[ "$char" == "$VS15" ]] || [[ "$char" == "$ZWJ" ]]; then
            ((i++))
            continue
        fi

        # Try to match emoji sequences (check longest first)
        local matched=0
        local emoji_key=""

        # Check up to 11 chars for ZWJ sequences (e.g., family emojis)
        local max_seq_len=11
        ((max_seq_len > len - i)) && max_seq_len=$((len - i))

        local seq_len
        for ((seq_len = max_seq_len; seq_len >= 1; seq_len--)); do
            local seq="${text:i:seq_len}"
            if [[ -n "${EMOJI_WIDTH[$seq]:-}" ]]; then
                emoji_key="$seq"
                matched=1
                break
            fi
        done

        if ((matched)); then
            if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$emoji_key]:-}" ]]; then
                ((width += EMOJI_WIDTH_LEGACY[$emoji_key]))
            else
                ((width += EMOJI_WIDTH[$emoji_key]))
            fi
            ((i += ${#emoji_key}))
        else
            # Regular character - check if wide
            local codepoint
            printf -v codepoint '%d' "'$char" 2>/dev/null || codepoint=0

            if ((codepoint > 127)) && _is_wide_char "$codepoint"; then
                ((width += 2))
            else
                ((width += 1))
            fi
            ((i++))
        fi
    done

    echo "$width"
}

################################################################################
# PADDING FUNCTIONS
################################################################################

# Pad string to target visual width
# Usage: pad_visual "text" width [left|right|center]
# Returns: padded string
pad_visual() {
    local text="$1"
    local target_width="$2"
    local align="${3:-left}"

    local current_width
    current_width=$(visual_width "$text")

    local padding=$((target_width - current_width))
    ((padding < 0)) && padding=0

    case "$align" in
        left)
            printf '%s%*s' "$text" "$padding" ""
            ;;
        right)
            printf '%*s%s' "$padding" "" "$text"
            ;;
        center)
            local left_pad=$((padding / 2))
            local right_pad=$((padding - left_pad))
            printf '%*s%s%*s' "$left_pad" "" "$text" "$right_pad" ""
            ;;
    esac
}

################################################################################
# TRUNCATION FUNCTIONS
################################################################################

# Truncate string to max visual width (with optional suffix)
# Usage: truncate_visual "text" max_width ["..."]
# Returns: truncated string, possibly with suffix
truncate_visual() {
    local text="$1"
    local max_width="$2"
    local suffix="${3:-}"

    # Strip ANSI for calculation but we need to track for restoration
    local clean_text
    clean_text=$(strip_ansi "$text")

    local current_width
    current_width=$(visual_width "$clean_text")

    # If already fits, return as-is
    if ((current_width <= max_width)); then
        echo "$clean_text"
        return
    fi

    local suffix_width=0
    [[ -n "$suffix" ]] && suffix_width=$(visual_width "$suffix")

    local effective_max=$((max_width - suffix_width))
    ((effective_max < 1)) && effective_max=1

    local result=""
    local width=0
    local i=0
    local len=${#clean_text}

    while ((i < len)); do
        local char="${clean_text:i:1}"

        # Include zero-width chars without counting width
        if [[ "$char" == "$VS16" ]] || [[ "$char" == "$VS15" ]] || [[ "$char" == "$ZWJ" ]]; then
            result+="$char"
            ((i++))
            continue
        fi

        # Determine character width
        local char_width=1

        # Check emoji table first
        local matched=0
        local max_seq_len=11
        ((max_seq_len > len - i)) && max_seq_len=$((len - i))

        local seq_len emoji_key
        for ((seq_len = max_seq_len; seq_len >= 1; seq_len--)); do
            local seq="${clean_text:i:seq_len}"
            if [[ -n "${EMOJI_WIDTH[$seq]:-}" ]]; then
                emoji_key="$seq"
                char_width="${EMOJI_WIDTH[$emoji_key]}"
                matched=1
                break
            fi
        done

        if ((matched)); then
            if ((width + char_width <= effective_max)); then
                result+="$emoji_key"
                ((width += char_width))
                ((i += ${#emoji_key}))
            else
                break
            fi
        else
            # Regular character
            local codepoint
            printf -v codepoint '%d' "'$char" 2>/dev/null || codepoint=0

            if ((codepoint > 127)) && _is_wide_char "$codepoint"; then
                char_width=2
            fi

            if ((width + char_width <= effective_max)); then
                result+="$char"
                ((width += char_width))
                ((i++))
            else
                break
            fi
        fi
    done

    # Add suffix if we truncated
    if ((i < len)); then
        echo "${result}${suffix}"
    else
        echo "$result"
    fi
}

################################################################################
# WIDTH COMPENSATION FOR GUM
################################################################################

# Calculate width adjustment for gum commands
# gum uses character count, not visual width - this calculates the difference
# Usage: gum_width_adjustment "text"
# Returns: adjustment value (can be positive or negative)
gum_width_adjustment() {
    local text="$1"
    local clean_text
    clean_text=$(strip_ansi "$text")

    local char_count=${#clean_text}
    local visual_w
    visual_w=$(visual_width "$clean_text")

    # Adjustment = char_count - visual_width
    # If positive: text has invisible chars (VS16/ZWJ), gum needs larger width
    # If negative: text has wide chars, gum needs smaller width
    echo $((char_count - visual_w))
}

# Calculate adjusted width for gum style command
# Usage: gum_adjusted_width "text" target_width
# Returns: width to pass to gum --width
gum_adjusted_width() {
    local text="$1"
    local target_width="$2"

    local adjustment
    adjustment=$(gum_width_adjustment "$text")

    echo $((target_width + adjustment))
}
