#!/usr/bin/env bash
# emoji_width_hybrid.sh - Experimental hybrid emoji width detection
#
# Combines:
# 1. Static lookup (fast, known emojis)
# 2. Unicode range heuristics (fast, unknown emojis)
# 3. Dynamic caching (learns as it goes)

[[ -n "${_EMOJI_WIDTH_HYBRID_LOADED:-}" ]] && return 0
_EMOJI_WIDTH_HYBRID_LOADED=1

# Source the static table
_HYBRID_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_HYBRID_DIR/emoji_data.sh"

# Dynamic cache for computed widths
declare -gA _EMOJI_WIDTH_DYNAMIC=()

# Stats for debugging
declare -g _EMOJI_CACHE_HITS=0
declare -g _EMOJI_RANGE_HITS=0
declare -g _EMOJI_FALLBACK_HITS=0

################################################################################
# UNICODE RANGE DETECTION
################################################################################

# Get numeric codepoint of first character
_get_codepoint() {
    printf '%d' "'${1:0:1}" 2>/dev/null || echo 0
}

# Check if codepoint is in emoji ranges (heuristic)
_is_emoji_codepoint() {
    local cp=$1

    # Emoticons
    ((cp >= 0x1F600 && cp <= 0x1F64F)) && return 0

    # Misc Symbols and Pictographs
    ((cp >= 0x1F300 && cp <= 0x1F5FF)) && return 0

    # Transport and Map
    ((cp >= 0x1F680 && cp <= 0x1F6FF)) && return 0

    # Supplemental Symbols
    ((cp >= 0x1F900 && cp <= 0x1F9FF)) && return 0

    # Symbols and Pictographs Extended-A
    ((cp >= 0x1FA00 && cp <= 0x1FA6F)) && return 0

    # Misc Symbols
    ((cp >= 0x2600 && cp <= 0x26FF)) && return 0

    # Dingbats
    ((cp >= 0x2700 && cp <= 0x27BF)) && return 0

    # Regional Indicators
    ((cp >= 0x1F1E0 && cp <= 0x1F1FF)) && return 0

    return 1
}

# Check if codepoint is CJK (wide characters)
_is_cjk_codepoint() {
    local cp=$1

    # CJK Unified Ideographs
    ((cp >= 0x4E00 && cp <= 0x9FFF)) && return 0

    # Hiragana
    ((cp >= 0x3040 && cp <= 0x309F)) && return 0

    # Katakana
    ((cp >= 0x30A0 && cp <= 0x30FF)) && return 0

    # Hangul Syllables
    ((cp >= 0xAC00 && cp <= 0xD7AF)) && return 0

    # Fullwidth Forms
    ((cp >= 0xFF00 && cp <= 0xFFEF)) && return 0

    return 1
}

# Check if character is ASCII printable
_is_ascii() {
    local cp=$1
    ((cp >= 32 && cp <= 126))
}

################################################################################
# HYBRID WIDTH FUNCTION
################################################################################

# Get visual width using hybrid approach
# Usage: emoji_width_hybrid "text"
emoji_width_hybrid() {
    local char="$1"
    local mode="${2:-${TERMINAL_MODE:-modern}}"

    # Empty string
    [[ -z "$char" ]] && {
        echo 0
        return
    }

    # 1. Check static cache (known emojis) - fastest
    if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$char]:-}" ]]; then
        ((_EMOJI_CACHE_HITS++))
        echo "${EMOJI_WIDTH_LEGACY[$char]}"
        return
    fi

    if [[ -n "${EMOJI_WIDTH[$char]:-}" ]]; then
        ((_EMOJI_CACHE_HITS++))
        echo "${EMOJI_WIDTH[$char]}"
        return
    fi

    # 2. Check dynamic cache (previously computed)
    local cache_key="${mode}:${char}"
    if [[ -n "${_EMOJI_WIDTH_DYNAMIC[$cache_key]:-}" ]]; then
        ((_EMOJI_CACHE_HITS++))
        echo "${_EMOJI_WIDTH_DYNAMIC[$cache_key]}"
        return
    fi

    # 3. Compute width using heuristics
    local width=0
    local cp

    # Handle multi-character strings
    local i=0 len=${#char}
    while ((i < len)); do
        local c="${char:i:1}"
        cp=$(_get_codepoint "$c")

        # Check for VS16 (invisible, skip)
        if ((cp == 0xFE0F)); then
            ((i++))
            continue
        fi

        # Check for ZWJ (invisible, skip)
        if ((cp == 0x200D)); then
            ((i++))
            continue
        fi

        # Determine character width
        if _is_ascii "$cp"; then
            ((width++))
        elif _is_emoji_codepoint "$cp"; then
            ((width += 2))
            ((_EMOJI_RANGE_HITS++))
        elif _is_cjk_codepoint "$cp"; then
            ((width += 2))
        else
            # Unknown - assume width 1
            ((width++))
            ((_EMOJI_FALLBACK_HITS++))
        fi

        ((i++))
    done

    # Cache the result
    _EMOJI_WIDTH_DYNAMIC["$cache_key"]=$width

    echo "$width"
}

# Show cache statistics
emoji_width_stats() {
    echo "Emoji Width Stats:"
    echo "  Static cache size: ${#EMOJI_WIDTH[@]}"
    echo "  Dynamic cache size: ${#_EMOJI_WIDTH_DYNAMIC[@]}"
    echo "  Cache hits: $_EMOJI_CACHE_HITS"
    echo "  Range detection hits: $_EMOJI_RANGE_HITS"
    echo "  Fallback hits: $_EMOJI_FALLBACK_HITS"
}

# Clear dynamic cache
emoji_width_clear_cache() {
    _EMOJI_WIDTH_DYNAMIC=()
    _EMOJI_CACHE_HITS=0
    _EMOJI_RANGE_HITS=0
    _EMOJI_FALLBACK_HITS=0
}
