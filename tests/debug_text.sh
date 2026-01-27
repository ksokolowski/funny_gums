#!/usr/bin/env bash
source lib/core/text.sh

debug_char() {
    local char="$1"
    local codepoint
    printf -v codepoint '%d' "'$char"
    echo "Char: $char, Codepoint: $codepoint"
    if _is_wide_char "$codepoint"; then echo "Wide: Yes"; else echo "Wide: No"; fi
    if _is_emoji_codepoint "$codepoint"; then echo "Emoji: Yes"; else echo "Emoji: No"; fi
    
    local w
    w=$(visual_width "$char")
    echo "Width: $w"
}

echo "--- Debugging ✅ ---"
debug_char "✅"

echo "--- Debugging Hiragana あ ---"
debug_char "あ"
