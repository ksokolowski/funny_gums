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

# Unicode constants for reference (using printf for portability)
# shellcheck disable=SC2155
readonly VS16=$(printf '\xef\xb8\x8f')  # U+FE0F Variation Selector 16 (emoji presentation)
# shellcheck disable=SC2155
readonly VS15=$(printf '\xef\xb8\x8e')  # U+FE0E Variation Selector 15 (text presentation)
# shellcheck disable=SC2155
readonly ZWJ=$(printf '\xe2\x80\x8d')   # U+200D Zero Width Joiner

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
# Build VS16 emoji keys programmatically using hex bytes to avoid git encoding
# issues. VS16 (U+FE0F) is appended to base emojis to create emoji presentation.
################################################################################
_emoji_data_init_vs16() {
    # Base emojis as hex:modern_width:legacy_width
    # Using hex bytes ensures consistent encoding across git operations
    local vs16_hex_emojis=(
        # Symbols: ⚙ ⏭ ⏮ ▶ ⏸ ⏹
        "e29a99:2:1" "e28fad:2:1" "e28fae:2:1" "e296b6:2:1" "e28fb8:2:1" "e28fb9:2:1"
        # Warning/hearts/weather: ⚠ ❤ ☀ ❄ ☁ ♻
        "e29aa0:2:1" "e29da4:2:1" "e29880:2:1" "e29d84:2:1" "e29881:2:1" "e299bb:2:1"
        # Objects: 🗑 🖥 🖨 🏷 🗄
        "f09f9791:2:1" "f09f96a5:2:1" "f09f96a8:2:1" "f09f8fb7:2:1" "f09f9784:2:1"
        # Media controls: ⏺ ⏏ ⌨ 🖱 🕹
        "e28fba:2:1" "e28f8f:2:1" "e28ca8:2:1" "f09f96b1:2:1" "f09f95b9:2:1"
        # Misc: ✂ 🌡 ☂ ⛈
        "e29c82:2:1" "f09f8ca1:2:1" "e29882:2:1" "e29b88:2:1"
        # Weather: 🌤 🌥 🌦 🌧 🌨 🌩
        "f09f8ca4:2:1" "f09f8ca5:2:1" "f09f8ca6:2:1" "f09f8ca7:2:1" "f09f8ca8:2:1" "f09f8ca9:2:1"
        # Decorations: 🎗 🎖 🏵 ⚗
        "f09f8e97:2:1" "f09f8e96:2:1" "f09f8fb5:2:1" "e29a97:2:1"
        # Objects: 🛡 ⚔ ⚰ ⚱ 🕳
        "f09f9ba1:2:1" "e29a94:2:1" "e29ab0:2:1" "e29ab1:2:1" "f09f95b3:2:1"
        # Speech: 🗨 🗯 👁 🕵 🗣
        "f09f97a8:2:1" "f09f97af:2:1" "f09f9181:2:1" "f09f95b5:2:1" "f09f97a3:2:1"
    )

    local entry hex modern_w legacy_w base
    for entry in "${vs16_hex_emojis[@]}"; do
        IFS=':' read -r hex modern_w legacy_w <<< "$entry"
        # Convert hex to character using printf
        base=$(printf "\\x${hex:0:2}\\x${hex:2:2}\\x${hex:4:2}")
        # Handle 4-byte UTF-8 (emojis starting with f0)
        if [[ ${#hex} -eq 8 ]]; then
            base=$(printf "\\x${hex:0:2}\\x${hex:2:2}\\x${hex:4:2}\\x${hex:6:2}")
        fi
        # Add VS16 variant to modern table
        EMOJI_WIDTH["${base}${VS16}"]=$modern_w
        # Add VS16 variant to legacy table
        EMOJI_WIDTH_LEGACY["${base}${VS16}"]=$legacy_w
    done

    # ZWJ sequences using hex bytes for consistency
    # 👨=f09f91a8 👩=f09f91a9 💻=f09f92bb 🏳=f09f8fb3 🌈=f09f8c88
    # 👧=f09f91a7 👦=f09f91a6 ❤=e29da4
    local man=$(printf '\xf0\x9f\x91\xa8')
    local woman=$(printf '\xf0\x9f\x91\xa9')
    local laptop=$(printf '\xf0\x9f\x92\xbb')
    local flag=$(printf '\xf0\x9f\x8f\xb3')
    local rainbow=$(printf '\xf0\x9f\x8c\x88')
    local girl=$(printf '\xf0\x9f\x91\xa7')
    local boy=$(printf '\xf0\x9f\x91\xa6')
    local heart=$(printf '\xe2\x9d\xa4')

    # ZWJ sequences for legacy terminals (show component emojis)
    EMOJI_WIDTH_LEGACY["${man}${ZWJ}${laptop}"]=4
    EMOJI_WIDTH_LEGACY["${woman}${ZWJ}${laptop}"]=4
    EMOJI_WIDTH_LEGACY["${flag}${VS16}${ZWJ}${rainbow}"]=4
    EMOJI_WIDTH_LEGACY["${man}${ZWJ}${woman}${ZWJ}${girl}"]=6
    EMOJI_WIDTH_LEGACY["${man}${ZWJ}${woman}${ZWJ}${girl}${ZWJ}${boy}"]=8
    EMOJI_WIDTH_LEGACY["${woman}${ZWJ}${heart}${VS16}${ZWJ}${man}"]=6
    EMOJI_WIDTH_LEGACY["${man}${ZWJ}${heart}${VS16}${ZWJ}${man}"]=6
    EMOJI_WIDTH_LEGACY["${woman}${ZWJ}${heart}${VS16}${ZWJ}${woman}"]=6

    # ZWJ sequences for modern terminals
    EMOJI_WIDTH["${man}${ZWJ}${laptop}"]=2
    EMOJI_WIDTH["${woman}${ZWJ}${laptop}"]=2
    EMOJI_WIDTH["${flag}${VS16}${ZWJ}${rainbow}"]=2
    EMOJI_WIDTH["${man}${ZWJ}${woman}${ZWJ}${girl}"]=2
    EMOJI_WIDTH["${man}${ZWJ}${woman}${ZWJ}${girl}${ZWJ}${boy}"]=2
    EMOJI_WIDTH["${woman}${ZWJ}${heart}${VS16}${ZWJ}${man}"]=2
    EMOJI_WIDTH["${man}${ZWJ}${heart}${VS16}${ZWJ}${man}"]=2
    EMOJI_WIDTH["${woman}${ZWJ}${heart}${VS16}${ZWJ}${woman}"]=2
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

    # DEBUG: Show what the function receives
    if [[ -n "${EMOJI_WIDTH_DEBUG:-}" ]]; then
        printf "FUNC_DEBUG: emoji hex: " >&2
        printf '%s' "$emoji" | xxd >&2
        echo "FUNC_DEBUG: array lookup: ${EMOJI_WIDTH[$emoji]:-NOT_FOUND}" >&2
    fi

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
