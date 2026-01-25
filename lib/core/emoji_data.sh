#!/usr/bin/env bash
# emoji_data.sh - Pre-computed emoji width lookup tables
#
# Instead of calculating emoji widths dynamically, we use pre-computed
# lookup tables for O(1) width queries. This enables proper handling of
# VS16 (Variation Selector 16) emojis in pure Bash.
#
# Usage:
#   source lib/core/emoji_data.sh
#   width=${EMOJI_WIDTH["⚙️"]:-2}

[[ -n "${_EMOJI_DATA_SH_LOADED:-}" ]] && return 0
_EMOJI_DATA_SH_LOADED=1

# Unicode constants for reference
readonly VS16=$'\ufe0f'      # Variation Selector 16 (emoji presentation)
readonly VS15=$'\ufe0e'      # Variation Selector 15 (text presentation)
readonly ZWJ=$'\u200d'       # Zero Width Joiner

################################################################################
# MODERN TERMINAL WIDTHS
# Width in modern terminals (most emojis render at width 2)
################################################################################
declare -gA EMOJI_WIDTH=(
    # Status indicators
    ["✅"]=2 ["❌"]=2 ["✓"]=1 ["✗"]=1
    ["🟢"]=2 ["🔴"]=2 ["🟡"]=2 ["🟠"]=2 ["🔵"]=2 ["🟣"]=2
    ["⚫"]=2 ["⚪"]=2 ["⬜"]=2 ["⬛"]=2

    # Colored squares
    ["🟥"]=2 ["🟧"]=2 ["🟨"]=2 ["🟩"]=2 ["🟦"]=2 ["🟪"]=2

    # Non-VS16 base characters (width 1 without VS16)
    ["⚙"]=1 ["⏭"]=1 ["⏮"]=1 ["▶"]=1 ["⏸"]=1 ["⏹"]=1
    ["⚠"]=1 ["❤"]=1 ["☀"]=1 ["❄"]=1 ["☁"]=1 ["♻"]=1
    ["🗑"]=2 ["🖥"]=2 ["🖨"]=2 ["🏷"]=2 ["🗄"]=2
    ["✂"]=1 ["🌡"]=2 ["☂"]=1 ["⛅"]=2 ["⛄"]=2
    ["⏺"]=1 ["⏏"]=1 ["⌨"]=1 ["🖱"]=2 ["🕹"]=2
    ["🎗"]=2 ["🎖"]=2 ["🏵"]=2 ["⚗"]=1
    ["🛡"]=2 ["⚔"]=1 ["⚰"]=2 ["⚱"]=2 ["🕳"]=2
    ["🗨"]=2 ["🗯"]=2 ["👁"]=2 ["🕵"]=2 ["🗣"]=2
    ["🌤"]=2 ["🌥"]=2 ["🌦"]=2 ["🌧"]=2 ["🌨"]=2 ["🌩"]=2 ["⛈"]=2

    # Common emojis
    ["🔧"]=2 ["🔨"]=2 ["🔩"]=2 ["🔑"]=2 ["🔐"]=2 ["🔓"]=2
    ["📁"]=2 ["📂"]=2 ["📄"]=2 ["📦"]=2 ["📋"]=2 ["📌"]=2
    ["💾"]=2 ["💿"]=2 ["💻"]=2
    ["🌐"]=2 ["🔗"]=2 ["📧"]=2 ["📱"]=2 ["📷"]=2
    ["⚡"]=2 ["🔥"]=2 ["💡"]=2 ["🔔"]=2 ["🔕"]=2
    ["🎯"]=2 ["🏆"]=2 ["🎉"]=2 ["✨"]=2 ["🌟"]=2 ["⭐"]=2
    ["🚀"]=2 ["🎮"]=2 ["🎵"]=2 ["🎬"]=2
    ["😊"]=2 ["😄"]=2 ["😎"]=2 ["🤔"]=2 ["😴"]=2 ["🤖"]=2
    ["👍"]=2 ["👎"]=2 ["👋"]=2 ["💪"]=2 ["🙏"]=2
    ["🧠"]=2 ["🌈"]=2 ["🌀"]=2 ["🔋"]=2 ["🔌"]=2
    ["⏩"]=2 ["⏳"]=2 ["🔄"]=2 ["🔃"]=2 ["🔁"]=2
    ["🕐"]=2 ["📅"]=2 ["🔖"]=2 ["🎤"]=2 ["🔊"]=2
    ["📢"]=2 ["📣"]=2 ["💬"]=2 ["💭"]=2 ["💥"]=2
    ["🚨"]=2 ["🏅"]=2 ["🚩"]=2 ["🏁"]=2 ["🎊"]=2
    ["🎈"]=2 ["🎁"]=2 ["👑"]=2 ["💎"]=2 ["💠"]=2
    ["🔶"]=2 ["🔷"]=2 ["🔸"]=2 ["🔹"]=2
    ["🧡"]=2 ["💛"]=2 ["💚"]=2 ["💙"]=2 ["💜"]=2
    ["🖤"]=2 ["🤍"]=2 ["💗"]=2 ["💖"]=2
    ["📥"]=2 ["🔍"]=2 ["📎"]=2 ["📝"]=2
    ["🍀"]=2 ["🌴"]=2 ["🌸"]=2 ["🌻"]=2 ["🌹"]=2 ["🌵"]=2 ["🍄"]=2
    ["💧"]=2 ["🌙"]=2
    ["🍎"]=2 ["🍊"]=2 ["🍋"]=2 ["🍇"]=2 ["🍓"]=2
    ["🍕"]=2 ["☕"]=2 ["🍺"]=2 ["🎂"]=2 ["🍪"]=2 ["🍬"]=2 ["🍦"]=2
    ["🐱"]=2 ["🐶"]=2 ["🦄"]=2 ["🐉"]=2 ["🦋"]=2 ["🐝"]=2
    ["🐢"]=2 ["🐰"]=2 ["🦉"]=2 ["🦊"]=2 ["🐧"]=2 ["🐙"]=2
    ["😉"]=2 ["😮"]=2 ["😢"]=2 ["😠"]=2 ["🤓"]=2 ["👻"]=2
    ["👏"]=2 ["👆"]=2 ["👇"]=2 ["👉"]=2 ["👈"]=2
    ["🔙"]=2 ["🔝"]=2 ["🔜"]=2 ["🆕"]=2 ["🆓"]=2 ["🆒"]=2 ["🆗"]=2 ["🆘"]=2
    ["❓"]=2 ["❗"]=2 ["💯"]=2 ["🧹"]=2
    ["♾"]=2 ["♻"]=2

    # Arrows and symbols (width 1 in most terminals - no VS16)
    ["⬆"]=1 ["⬇"]=1 ["⬅"]=1 ["➡"]=1
    ["•"]=1 ["→"]=1 ["←"]=1 ["↑"]=1 ["↓"]=1
    ["❇"]=1

    # ZWJ sequences (rendered as single emoji in modern terminals)
    ["👨‍💻"]=2 ["👩‍💻"]=2 ["🏳️‍🌈"]=2 ["👨‍👩‍👧"]=2
    ["👨‍👩‍👧‍👦"]=2 ["👩‍❤️‍👨"]=2 ["👨‍❤️‍👨"]=2 ["👩‍❤️‍👩"]=2
)

################################################################################
# LEGACY TERMINAL WIDTHS
# VS16 emojis often render narrower in legacy terminals
# ZWJ sequences often break apart showing multiple characters
################################################################################
declare -gA EMOJI_WIDTH_LEGACY=()

################################################################################
# VS16 KEY GENERATION
# Build VS16 emoji keys programmatically to avoid git encoding issues
# VS16 (U+FE0F) is appended to base emojis to create emoji presentation
################################################################################
_emoji_data_init_vs16() {
    # Base emojis that have VS16 variants (base_char:modern_width:legacy_width)
    local vs16_emojis=(
        "⚙:2:1" "⏭:2:1" "⏮:2:1" "▶:2:1" "⏸:2:1" "⏹:2:1"
        "⚠:2:1" "❤:2:1" "☀:2:1" "❄:2:1" "☁:2:1" "♻:2:1"
        "🗑:2:1" "🖥:2:1" "🖨:2:1" "🏷:2:1" "🗄:2:1"
        "⏺:2:1" "⏏:2:1" "⌨:2:1" "🖱:2:1" "🕹:2:1"
        "✂:2:1" "🌡:2:1" "☂:2:1" "⛈:2:1"
        "🌤:2:1" "🌥:2:1" "🌦:2:1" "🌧:2:1" "🌨:2:1" "🌩:2:1"
        "🎗:2:1" "🎖:2:1" "🏵:2:1" "⚗:2:1"
        "🛡:2:1" "⚔:2:1" "⚰:2:1" "⚱:2:1" "🕳:2:1"
        "🗨:2:1" "🗯:2:1" "👁:2:1" "🕵:2:1" "🗣:2:1"
    )

    local entry base modern_w legacy_w
    for entry in "${vs16_emojis[@]}"; do
        IFS=':' read -r base modern_w legacy_w <<< "$entry"
        # Add VS16 variant to modern table
        EMOJI_WIDTH["${base}${VS16}"]=$modern_w
        # Add VS16 variant to legacy table
        EMOJI_WIDTH_LEGACY["${base}${VS16}"]=$legacy_w
    done

    # ZWJ sequences for legacy terminals (show component emojis)
    # Built programmatically to avoid encoding issues
    EMOJI_WIDTH_LEGACY["👨${ZWJ}💻"]=4
    EMOJI_WIDTH_LEGACY["👩${ZWJ}💻"]=4
    EMOJI_WIDTH_LEGACY["🏳${VS16}${ZWJ}🌈"]=4
    EMOJI_WIDTH_LEGACY["👨${ZWJ}👩${ZWJ}👧"]=6
    EMOJI_WIDTH_LEGACY["👨${ZWJ}👩${ZWJ}👧${ZWJ}👦"]=8
    EMOJI_WIDTH_LEGACY["👩${ZWJ}❤${VS16}${ZWJ}👨"]=6
    EMOJI_WIDTH_LEGACY["👨${ZWJ}❤${VS16}${ZWJ}👨"]=6
    EMOJI_WIDTH_LEGACY["👩${ZWJ}❤${VS16}${ZWJ}👩"]=6

    # ZWJ sequences for modern terminals
    EMOJI_WIDTH["👨${ZWJ}💻"]=2
    EMOJI_WIDTH["👩${ZWJ}💻"]=2
    EMOJI_WIDTH["🏳${VS16}${ZWJ}🌈"]=2
    EMOJI_WIDTH["👨${ZWJ}👩${ZWJ}👧"]=2
    EMOJI_WIDTH["👨${ZWJ}👩${ZWJ}👧${ZWJ}👦"]=2
    EMOJI_WIDTH["👩${ZWJ}❤${VS16}${ZWJ}👨"]=2
    EMOJI_WIDTH["👨${ZWJ}❤${VS16}${ZWJ}👨"]=2
    EMOJI_WIDTH["👩${ZWJ}❤${VS16}${ZWJ}👩"]=2
}

# Initialize VS16 keys
_emoji_data_init_vs16

################################################################################
# HELPER FUNCTIONS
################################################################################

# Get emoji width for current terminal mode
# Usage: emoji_width "emoji" [modern|legacy]
# Returns: width as integer (default: 2 for unknown emojis)
emoji_width() {
    local emoji="$1"
    local mode="${2:-${TERMINAL_MODE:-modern}}"

    # Check legacy table first if in legacy mode
    if [[ "$mode" == "legacy" ]] && [[ -n "${EMOJI_WIDTH_LEGACY[$emoji]:-}" ]]; then
        echo "${EMOJI_WIDTH_LEGACY[$emoji]}"
        return
    fi

    # Check main table
    if [[ -n "${EMOJI_WIDTH[$emoji]:-}" ]]; then
        echo "${EMOJI_WIDTH[$emoji]}"
        return
    fi

    # Default: assume width 2 for unknown emojis (safer than 1)
    echo "2"
}

# Check if a string contains any VS16 sequences
# Usage: has_vs16 "string"
# Returns: 0 if contains VS16, 1 otherwise
has_vs16() {
    [[ "$1" == *"$VS16"* ]]
}

# Check if a string contains any ZWJ sequences
# Usage: has_zwj "string"
# Returns: 0 if contains ZWJ, 1 otherwise
has_zwj() {
    [[ "$1" == *"$ZWJ"* ]]
}
