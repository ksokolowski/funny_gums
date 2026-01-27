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
# Strip ANSI escape sequences from text (pure bash)
# Usage: strip_ansi "colored text"
# Returns: text without ANSI codes
strip_ansi() {
    local text="$1"
    local result=""
    local i=0
    local len=${#text}
    
    while ((i < len)); do
        local char="${text:i:1}"
        if [[ "$char" == $'\e' ]]; then
            if [[ "${text:i+1:1}" == "[" ]]; then
                ((i += 2))
                while ((i < len)); do
                    local next_c="${text:i:1}"
                    ((i++))
                    [[ "$next_c" =~ [a-zA-Z] ]] && break
                done
                continue
            fi
            ((i++))
            continue
        fi
        result+="$char"
        ((i++))
    done
    echo "$result"
}

# Calculate length of string ignoring ANSI codes (pure bash)
strlen_no_ansi() {
    local text="$1"
    local len=0
    local i=0
    local input_len=${#text}
    
    # Fast path
    if [[ "$text" != *$'\e'* ]]; then
        echo "$input_len"
        return
    fi
    
    while ((i < input_len)); do
        local char="${text:i:1}"
        if [[ "$char" == $'\e' ]]; then
            if [[ "${text:i+1:1}" == "[" ]]; then
                ((i += 2))
                while ((i < input_len)); do
                    local next_c="${text:i:1}"
                    ((i++))
                    [[ "$next_c" =~ [a-zA-Z] ]] && break
                done
                continue
            fi
            ((i++))
            continue
        fi
        ((len++))
        ((i++))
    done
    echo "$len"
}

# Calculate length of string ignoring ANSI codes (sets variable)
# Usage: strlen_no_ansi_ref "text" var_name
strlen_no_ansi_ref() {
    local text="$1"
    local len=0
    local i=0
    local input_len=${#text}
    
    # Fast path
    if [[ "$text" != *$'\e'* ]]; then
        printf -v "$2" '%d' "$input_len"
        return
    fi
    
    while ((i < input_len)); do
        local char="${text:i:1}"
        if [[ "$char" == $'\e' ]]; then
            if [[ "${text:i+1:1}" == "[" ]]; then
                ((i += 2))
                while ((i < input_len)); do
                    local next_c="${text:i:1}"
                    ((i++))
                    [[ "$next_c" =~ [a-zA-Z] ]] && break
                done
                continue
            fi
            ((i++))
            continue
        fi
        ((len++))
        ((i++))
    done
    printf -v "$2" '%d' "$len"
}

# Get visual width without subshell (sets variable)
# Usage: visual_width_ref "text" var_name [mode]
visual_width_ref() {
    local width
    width=$(visual_width "$1" "$3")
    printf -v "$2" '%s' "$width"
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
# VISUAL WIDTH CALCULATION (Hybrid approach - 57x faster)
################################################################################

# Dynamic cache for computed widths
declare -gA _VISUAL_WIDTH_CACHE=()

# Check if codepoint is in emoji ranges (heuristic)
_is_emoji_codepoint() {
    local cp=$1
    # Emoticons, Misc Symbols, Transport, Supplemental, etc.
    (( cp >= 0x1F300 && cp <= 0x1F9FF )) && return 0
    (( cp >= 0x1FA00 && cp <= 0x1FA6F )) && return 0
    (( cp >= 0x2600 && cp <= 0x26FF )) && return 0
    (( cp >= 0x2700 && cp <= 0x27BF )) && return 0
    (( cp >= 0x1F1E0 && cp <= 0x1F1FF )) && return 0
    return 1
}

# Calculate visual width of a string (display columns)
# Handles ANSI codes, VS16/VS15, ZWJ, wide chars, and emoji
# Usage: visual_width "string" [modern|legacy]
# Returns: integer width in terminal columns
visual_width() {
    local text="$1"
    local mode="${2:-${TERMINAL_MODE:-modern}}"

    # Empty string has width 0
    [[ -z "$text" ]] && { echo 0; return; }

    # Check cache first
    local cache_key="${mode}:${text}"
    [[ -n "${_VISUAL_WIDTH_CACHE[$cache_key]:-}" ]] && { echo "${_VISUAL_WIDTH_CACHE[$cache_key]}"; return; }

    # Fast path: pure ASCII printable characters without ANSI
    # We check if the string contains only ASCII characters (0x20-0x7E)
    local ascii_regex='^[ -~]*$'
    if [[ "$text" =~ $ascii_regex ]]; then
         local len=${#text}
         _VISUAL_WIDTH_CACHE[$cache_key]=$len
         echo "$len"
         return
    fi
    
    # Check if entire string is in emoji table (single emoji)
    if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$text]:-}" ]]; then
        _VISUAL_WIDTH_CACHE[$cache_key]="${EMOJI_WIDTH_LEGACY[$text]}"
        echo "${EMOJI_WIDTH_LEGACY[$text]}"
        return
    fi
    if [[ -n "${EMOJI_WIDTH[$text]:-}" ]]; then
        _VISUAL_WIDTH_CACHE[$cache_key]="${EMOJI_WIDTH[$text]}"
        echo "${EMOJI_WIDTH[$text]}"
        return
    fi

    # Character-by-character processing
    local width=0
    local i=0
    local len=${#text}
    local char codepoint

    while ((i < len)); do
        char="${text:i:1}"
        
        # ANSI ESC detection (pure bash)
        if [[ "$char" == $'\e' ]]; then
            # Look ahead for [
            if [[ "${text:i+1:1}" == "[" ]]; then
                # Found CSI sequence starter \e[
                ((i += 2)) # Skip \e and [
                # Advance until we find a letter (terminator)
                while ((i < len)); do
                    local next_c="${text:i:1}"
                    ((i++))
                    # Check if it's a letter (a-z, A-Z)
                    if [[ "$next_c" =~ [a-zA-Z] ]]; then
                        break
                    fi
                done
                continue
            else
                # Non-CSI escape, just skip the ESC char
                ((i++))
                continue
            fi
        fi

        printf -v codepoint '%d' "'$char" 2>/dev/null || codepoint=0

        # Skip zero-width characters (VS16, VS15, ZWJ)
        if (( codepoint == 0xFE0F || codepoint == 0xFE0E || codepoint == 0x200D )); then
            ((i++))
            continue
        fi

        # Check for char + VS16 sequence (2 chars)
        if (( i + 1 < len )); then
            local next_char="${text:i+1:1}"
            local next_cp
            printf -v next_cp '%d' "'$next_char" 2>/dev/null || next_cp=0
            if (( next_cp == 0xFE0F )); then
                # This is a VS16 emoji sequence
                local seq="${char}${next_char}"
                if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$seq]:-}" ]]; then
                    ((width += EMOJI_WIDTH_LEGACY[$seq]))
                elif [[ -n "${EMOJI_WIDTH[$seq]:-}" ]]; then
                    ((width += EMOJI_WIDTH[$seq]))
                elif [[ "$mode" == "legacy" ]]; then
                    # VS16 emoji not in table, legacy mode - assume width 1
                    ((width += 1))
                else
                    # VS16 emoji not in table, modern mode - assume width 2
                    ((width += 2))
                fi
                ((i += 2))
                continue
            fi
        fi

        # Check single char in emoji table
        if [[ -n "${EMOJI_WIDTH[$char]:-}" ]]; then
            if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$char]:-}" ]]; then
                ((width += EMOJI_WIDTH_LEGACY[$char]))
            else
                ((width += EMOJI_WIDTH[$char]))
            fi
            ((i++))
            continue
        fi

        # Use heuristics for unknown characters
        if (( codepoint < 128 )); then
            # ASCII
            ((width++))
        elif _is_emoji_codepoint "$codepoint"; then
            # Emoji range
            ((width += 2))
        elif _is_wide_char "$codepoint"; then
            # CJK/wide
            ((width += 2))
        else
            # Unknown - assume 1
            ((width++))
        fi
        ((i++))
    done

    # Cache result
    _VISUAL_WIDTH_CACHE[$cache_key]=$width
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
# VS16 HANDLING
################################################################################

# VS16 (Variation Selector 16) causes width calculation issues in some terminals.
# VTE-based terminals (GNOME Terminal, Tilix) display VS16 emojis at width 2
# but gum's Go runewidth calculates them as width 1, causing misalignment.
#
# The solution is to strip VS16 from text for "compatible" terminals.
# The emoji still displays correctly, just without the presentation selector.

# Strip VS16 (U+FE0F) from text
# Usage: text=$(strip_vs16 "$text")
# Returns: text with VS16 bytes removed
strip_vs16() {
    local text="$1"
    # VS16 in UTF-8 is \xef\xb8\x8f (3 bytes)
    printf '%s' "${text//$VS16/}"
}

# Make text safe for current terminal by applying necessary transformations
# - For "full" terminals: returns text unchanged
# - For "compatible" terminals: strips VS16 for proper gum alignment
# - For "legacy" terminals: returns text unchanged (fallbacks should already be applied)
# Usage: text=$(terminal_safe_text "$text")
terminal_safe_text() {
    local text="$1"
    [[ -z "$TERMINAL_CAPABILITY" ]] && detect_terminal_capability

    if needs_vs16_stripping; then
        strip_vs16 "$text"
    else
        printf '%s' "$text"
    fi
}

# DEPRECATED: Use needs_vs16_stripping() and strip_vs16() instead
# This function only stripped VS16 for VTE terminals.
# The new approach uses the 3-tier terminal classification.
fix_vte_vs16() {
    local text="$1"
    # Only apply fix for VTE terminals (compatible tier)
    if [[ -z "${VTE_VERSION:-}" ]]; then
        printf '%s' "$text"
        return
    fi
    strip_vs16 "$text"
}

# Legacy alias (DEPRECATED)
fix_vs16_spacing() {
    fix_vte_vs16 "$@"
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
