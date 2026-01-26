#!/usr/bin/env bash
# test_text.sh - Tests for text.sh visual width functions
# shellcheck disable=SC2034

set -uo pipefail

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

################################################################################
# TERMINAL DETECTION TESTS (3-Tier Classification)
################################################################################

test_file_start "terminal.sh"
source "$PROJECT_DIR/lib/core/terminal.sh"

# Test function existence
assert_function_exists "is_modern_terminal"
assert_function_exists "detect_terminal_mode"
assert_function_exists "get_terminal_mode"
assert_function_exists "detect_terminal_capability"
assert_function_exists "get_terminal_capability"
assert_function_exists "needs_vs16_stripping"
assert_function_exists "supports_zwj"

# Test detect_terminal_capability sets TERMINAL_CAPABILITY
detect_terminal_capability
assert_not_empty "$TERMINAL_CAPABILITY" "TERMINAL_CAPABILITY should be set after detect"
assert_contains "$TERMINAL_CAPABILITY" "full compatible legacy" "TERMINAL_CAPABILITY should be 'full', 'compatible', or 'legacy'"

# Test backward compat TERMINAL_MODE is also set
assert_not_empty "$TERMINAL_MODE" "TERMINAL_MODE should be set for backward compat"
assert_contains "$TERMINAL_MODE" "modern legacy" "TERMINAL_MODE should be 'modern' or 'legacy'"

# Test legacy override
FUNNY_GUMS_LEGACY_TERMINAL=1 detect_terminal_capability
assert_eq "legacy" "$TERMINAL_CAPABILITY" "FUNNY_GUMS_LEGACY_TERMINAL=1 should force legacy capability"
assert_eq "legacy" "$TERMINAL_MODE" "FUNNY_GUMS_LEGACY_TERMINAL=1 should force legacy mode"
unset FUNNY_GUMS_LEGACY_TERMINAL

# Test explicit capability override
TERMINAL_CAPABILITY="" TERMINAL_MODE=""
FUNNY_GUMS_TERMINAL_CAPABILITY=full detect_terminal_capability
assert_eq "full" "$TERMINAL_CAPABILITY" "FUNNY_GUMS_TERMINAL_CAPABILITY=full should force full"
unset FUNNY_GUMS_TERMINAL_CAPABILITY

TERMINAL_CAPABILITY="" TERMINAL_MODE=""
FUNNY_GUMS_TERMINAL_CAPABILITY=compatible detect_terminal_capability
assert_eq "compatible" "$TERMINAL_CAPABILITY" "FUNNY_GUMS_TERMINAL_CAPABILITY=compatible should force compatible"
unset FUNNY_GUMS_TERMINAL_CAPABILITY

# Test needs_vs16_stripping
TERMINAL_CAPABILITY="full"
result=$(needs_vs16_stripping && echo "yes" || echo "no")
assert_eq "no" "$result" "Full terminals should not need VS16 stripping"

TERMINAL_CAPABILITY="compatible"
result=$(needs_vs16_stripping && echo "yes" || echo "no")
assert_eq "yes" "$result" "Compatible terminals should need VS16 stripping"

TERMINAL_CAPABILITY="legacy"
result=$(needs_vs16_stripping && echo "yes" || echo "no")
assert_eq "no" "$result" "Legacy terminals should not need VS16 stripping"

# Test supports_zwj
TERMINAL_CAPABILITY="full"
result=$(supports_zwj && echo "yes" || echo "no")
assert_eq "yes" "$result" "Full terminals should support ZWJ"

TERMINAL_CAPABILITY="compatible"
result=$(supports_zwj && echo "yes" || echo "no")
assert_eq "no" "$result" "Compatible terminals should not fully support ZWJ"

TERMINAL_CAPABILITY="legacy"
result=$(supports_zwj && echo "yes" || echo "no")
assert_eq "no" "$result" "Legacy terminals should not support ZWJ"

# Force full mode for remaining VS16 tests (CI environments default to legacy)
TERMINAL_CAPABILITY="full"
TERMINAL_MODE="modern"

################################################################################
# EMOJI DATA TESTS
################################################################################

test_file_start "emoji_data.sh"
source "$PROJECT_DIR/lib/core/emoji_data.sh"

assert_function_exists "emoji_width"
assert_function_exists "has_vs16"
assert_function_exists "has_zwj"

# Test unicode constants
assert_not_empty "$VS16" "VS16 constant should be defined"
assert_not_empty "$ZWJ" "ZWJ constant should be defined"

# Test emoji width lookups
assert_eq "2" "$(emoji_width "✅")" "Checkmark emoji should have width 2"
assert_eq "2" "$(emoji_width "🔧")" "Wrench emoji should have width 2"
assert_eq "1" "$(emoji_width "▶")" "Play symbol (no VS16) should have width 1"

# Build VS16 emojis programmatically to avoid encoding issues
# Use printf for base characters too to ensure consistent encoding
GEAR_BASE=$(printf '\xe2\x9a\x99')   # U+2699 GEAR
PLAY_BASE=$(printf '\xe2\x96\xb6')   # U+25B6 BLACK RIGHT-POINTING TRIANGLE
NEXT_BASE=$(printf '\xe2\x8f\xad')   # U+23ED BLACK RIGHT-POINTING DOUBLE TRIANGLE WITH VERTICAL BAR
GEAR_VS16="${GEAR_BASE}${VS16}"
PLAY_VS16="${PLAY_BASE}${VS16}"
NEXT_VS16="${NEXT_BASE}${VS16}"

assert_eq "2" "$(emoji_width "$PLAY_VS16")" "Play symbol (with VS16) should have width 2"
assert_eq "2" "$(emoji_width "$GEAR_VS16")" "Gear with VS16 should have width 2"

# Test legacy mode widths
assert_eq "1" "$(emoji_width "$GEAR_VS16" "legacy")" "Gear with VS16 in legacy mode should have width 1"
assert_eq "1" "$(emoji_width "$PLAY_VS16" "legacy")" "Play with VS16 in legacy mode should have width 1"

# Test has_vs16 (using programmatically built VS16 emoji)
result=$(has_vs16 "$GEAR_VS16" && echo "yes" || echo "no")
assert_eq "yes" "$result" "has_vs16 should detect VS16 in gear emoji"

result=$(has_vs16 "🔧" && echo "yes" || echo "no")
assert_eq "no" "$result" "has_vs16 should not detect VS16 in wrench emoji"

# Test has_zwj (using programmatically built ZWJ emoji with hex bytes)
MAN_EMOJI=$(printf '\xf0\x9f\x91\xa8')
LAPTOP_EMOJI=$(printf '\xf0\x9f\x92\xbb')
TECH_ZWJ="${MAN_EMOJI}${ZWJ}${LAPTOP_EMOJI}"
result=$(has_zwj "$TECH_ZWJ" && echo "yes" || echo "no")
assert_eq "yes" "$result" "has_zwj should detect ZWJ in technologist emoji"

result=$(has_zwj "🔧" && echo "yes" || echo "no")
assert_eq "no" "$result" "has_zwj should not detect ZWJ in wrench emoji"

################################################################################
# EMOJI REGISTRY TESTS
################################################################################

test_file_start "emoji_registry.sh"
source "$PROJECT_DIR/lib/core/emoji_registry.sh"

assert_function_exists "emoji"
assert_function_exists "emoji_variant"
assert_function_exists "is_registered_emoji"
assert_function_exists "strip_vs16"
assert_function_exists "_export_emoji_vars"

# Test registry has entries
result=$(is_registered_emoji "WARNING" && echo "yes" || echo "no")
assert_eq "yes" "$result" "WARNING should be registered"

result=$(is_registered_emoji "CPU" && echo "yes" || echo "no")
assert_eq "yes" "$result" "CPU should be registered"

result=$(is_registered_emoji "NONEXISTENT" && echo "yes" || echo "no")
assert_eq "no" "$result" "NONEXISTENT should not be registered"

# Test emoji_variant returns different values for each tier
warning_full=$(emoji_variant "WARNING" "full")
warning_compat=$(emoji_variant "WARNING" "compatible")
warning_legacy=$(emoji_variant "WARNING" "legacy")
assert_not_empty "$warning_full" "WARNING full variant should exist"
assert_not_empty "$warning_compat" "WARNING compatible variant should exist"
assert_not_empty "$warning_legacy" "WARNING legacy variant should exist"

# Full should have VS16 (contains 0xFE0F bytes)
((TESTS_RUN++))
if [[ "$warning_full" == *$'\xef\xb8\x8f'* ]]; then
    echo "  ${GREEN}✓${RESET} WARNING full variant contains VS16"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} WARNING full variant should contain VS16"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("emoji_registry.sh: WARNING full variant should contain VS16")
fi

# Test emoji() function returns appropriate variant based on capability
TERMINAL_CAPABILITY="full"
result=$(emoji "WARNING")
assert_eq "$warning_full" "$result" "emoji() should return full variant when capability is full"

TERMINAL_CAPABILITY="compatible"
result=$(emoji "WARNING")
assert_eq "$warning_compat" "$result" "emoji() should return compatible variant when capability is compatible"

TERMINAL_CAPABILITY="legacy"
result=$(emoji "WARNING")
assert_eq "$warning_legacy" "$result" "emoji() should return legacy variant when capability is legacy"

# Test strip_vs16
vs16_text=$'\xe2\x9a\xa0\xef\xb8\x8f'  # ⚠️
stripped=$(strip_vs16 "$vs16_text")
expected=$'\xe2\x9a\xa0'  # ⚠ (no VS16)
assert_eq "$expected" "$stripped" "strip_vs16 should remove VS16 bytes"

# Test _export_emoji_vars sets EMOJI_ variables
TERMINAL_CAPABILITY="full"
_export_emoji_vars
assert_not_empty "${EMOJI_WARNING:-}" "EMOJI_WARNING should be set after _export_emoji_vars"
assert_not_empty "${EMOJI_CPU:-}" "EMOJI_CPU should be set after _export_emoji_vars"

# Reset to full for remaining tests
TERMINAL_CAPABILITY="full"
TERMINAL_MODE="modern"

################################################################################
# TEXT WIDTH TESTS
################################################################################

test_file_start "text.sh"
source "$PROJECT_DIR/lib/core/text.sh"

assert_function_exists "strip_ansi"
assert_function_exists "visual_width"
assert_function_exists "pad_visual"
assert_function_exists "truncate_visual"
assert_function_exists "gum_width_adjustment"
assert_function_exists "gum_adjusted_width"
assert_function_exists "strip_vs16"
assert_function_exists "terminal_safe_text"
assert_function_exists "fix_vte_vs16"

# Test strip_vs16 from text.sh (duplicate in emoji_registry.sh for convenience)
vs16_emoji=$'\xe2\x9a\xa0\xef\xb8\x8f'  # ⚠️
result=$(strip_vs16 "$vs16_emoji")
expected=$'\xe2\x9a\xa0'  # ⚠
assert_eq "$expected" "$result" "strip_vs16 should remove VS16 from emoji"

# Test terminal_safe_text
TERMINAL_CAPABILITY="full"
result=$(terminal_safe_text "$vs16_emoji")
assert_eq "$vs16_emoji" "$result" "terminal_safe_text should preserve VS16 for full terminals"

TERMINAL_CAPABILITY="compatible"
result=$(terminal_safe_text "$vs16_emoji")
assert_eq "$expected" "$result" "terminal_safe_text should strip VS16 for compatible terminals"

TERMINAL_CAPABILITY="legacy"
result=$(terminal_safe_text "$vs16_emoji")
assert_eq "$vs16_emoji" "$result" "terminal_safe_text should preserve text for legacy terminals"

# Reset for remaining tests
TERMINAL_CAPABILITY="full"
TERMINAL_MODE="modern"

# Test strip_ansi
plain=$(strip_ansi $'\e[31mRed\e[0m')
assert_eq "Red" "$plain" "strip_ansi should remove color codes"

plain=$(strip_ansi $'\e[1;32mBold Green\e[0m')
assert_eq "Bold Green" "$plain" "strip_ansi should remove bold color codes"

# Test visual_width - basic ASCII
assert_eq "5" "$(visual_width "Hello")" "ASCII string 'Hello' should have width 5"
assert_eq "0" "$(visual_width "")" "Empty string should have width 0"
assert_eq "11" "$(visual_width "Hello World")" "ASCII with space should work"

# Test visual_width - emojis
assert_eq "2" "$(visual_width "✅")" "Single emoji should have width 2"
assert_eq "7" "$(visual_width "Hello✅")" "String + emoji: 5 + 2 = 7"
# "Hello ✅" = H(1) + e(1) + l(1) + l(1) + o(1) + space(1) + ✅(2) = 8
assert_eq "8" "$(visual_width "Hello ✅")" "String + space + emoji: 5 + 1 + 2 = 8"

# Test visual_width - VS16 emojis (built programmatically)
assert_eq "2" "$(visual_width "$GEAR_VS16")" "Gear with VS16 should have width 2"
THREE_NEXT_VS16="${NEXT_VS16}${NEXT_VS16}${NEXT_VS16}"
assert_eq "6" "$(visual_width "$THREE_NEXT_VS16")" "Three VS16 emojis: 3 x 2 = 6"

# Test visual_width with ANSI codes (should be stripped)
assert_eq "5" "$(visual_width $'\e[31mHello\e[0m')" "ANSI codes should be ignored"

# Test visual_width - arrows (no VS16, width 1)
assert_eq "1" "$(visual_width "▶")" "Play without VS16 should have width 1"
assert_eq "3" "$(visual_width "▶▶▶")" "Three play symbols: 3 x 1 = 3"

################################################################################
# PADDING TESTS
################################################################################

# Test pad_visual - left align (default)
result=$(pad_visual "Hi" 10)
assert_eq "Hi        " "$result" "pad_visual left should add spaces on right"

# Test pad_visual - right align
result=$(pad_visual "Hi" 10 right)
assert_eq "        Hi" "$result" "pad_visual right should add spaces on left"

# Test pad_visual - center align
result=$(pad_visual "Hi" 10 center)
assert_eq "    Hi    " "$result" "pad_visual center should add spaces on both sides"

# Test pad_visual with emoji
result=$(pad_visual "✅" 6)
# ✅ is width 2, so we need 4 spaces to reach width 6
assert_eq "✅    " "$result" "pad_visual with emoji should account for visual width"

# Test pad_visual - text already at target width
result=$(pad_visual "Hello" 5)
assert_eq "Hello" "$result" "pad_visual should not add padding if already at width"

################################################################################
# TRUNCATION TESTS
################################################################################

# Test truncate_visual - no truncation needed
result=$(truncate_visual "Hello" 10)
assert_eq "Hello" "$result" "truncate_visual should not truncate if within limit"

# Test truncate_visual - basic truncation
result=$(truncate_visual "Hello World" 8 "...")
assert_eq "Hello..." "$result" "truncate_visual should truncate and add suffix"

# Test truncate_visual - truncation without suffix
result=$(truncate_visual "Hello World" 5)
assert_eq "Hello" "$result" "truncate_visual without suffix should just truncate"

# Test truncate_visual with emoji
result=$(truncate_visual "A✅B" 4)
# A(1) + ✅(2) = 3, fits in 4
assert_eq "A✅B" "$result" "truncate_visual with emoji that fits"

result=$(truncate_visual "A✅BC" 3)
# Max 3, A(1) + ✅(2) = 3, B would make 4
assert_eq "A✅" "$result" "truncate_visual with emoji at boundary"

################################################################################
# GUM WIDTH ADJUSTMENT TESTS
################################################################################

# Test gum_width_adjustment - ASCII
result=$(gum_width_adjustment "Hello")
assert_eq "0" "$result" "ASCII text should have no adjustment"

# Test gum_width_adjustment - VS16 emoji (using programmatically built emoji)
# GEAR_VS16 has char length ~3 (base + VS16) but visual width 2
# The VS16 is invisible, so adjustment should be positive
result=$(gum_width_adjustment "$GEAR_VS16")
# char_count - visual_width: if ⚙️ is 2 chars and width 2, adjustment is 0
# But ⚙️ includes VS16 which is an extra char
# Let's check actual behavior

# Test gum_adjusted_width
result=$(gum_adjusted_width "Hello" 20)
# No emojis, no adjustment needed
assert_eq "20" "$result" "ASCII text needs no width adjustment for gum"

################################################################################
# WIDE CHARACTER TESTS
################################################################################

# Test _is_wide_char function (CJK characters)
# We can test this indirectly through visual_width

# Japanese hiragana (should be width 2)
assert_eq "2" "$(visual_width "あ")" "Japanese hiragana should have width 2"

# Chinese character (should be width 2)
assert_eq "2" "$(visual_width "中")" "Chinese character should have width 2"

# Mixed ASCII and CJK
assert_eq "7" "$(visual_width "Hello中")" "ASCII + CJK: 5 + 2 = 7"

################################################################################
# EDGE CASES
################################################################################

# Test with multiple emojis
assert_eq "4" "$(visual_width "✅✅")" "Two emojis: 2 + 2 = 4"
assert_eq "8" "$(visual_width "🔧🔨🔩🔑")" "Four emojis: 4 x 2 = 8"

# Test mixed content: H(1) + i(1) + space(1) + ✅(2) + space(1) + o(1) + k(1) = 8
assert_eq "8" "$(visual_width "Hi ✅ ok")" "Mixed: H(1)+i(1)+sp(1)+✅(2)+sp(1)+o(1)+k(1) = 8"

echo ""
echo "All text.sh tests complete!"
