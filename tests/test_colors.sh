#!/usr/bin/env bash
# test_colors.sh - Unit tests for colors.sh

test_file_start "colors.sh"

# Source the module
source "$PROJECT_DIR/lib/core/term/colors.sh"

# Test that color variables are defined
assert_var_defined "RED"
assert_var_defined "GREEN"
assert_var_defined "BLUE"
assert_var_defined "CYAN"
assert_var_defined "YELLOW"
assert_var_defined "RESET"
assert_var_defined "BOLD"

# Test that colors contain escape sequences
assert_not_empty "$RED" "RED should not be empty"
assert_not_empty "$RESET" "RESET should not be empty"

# Test colorize function exists
assert_function_exists "colorize"

# Test colorize function output
output=$(colorize "$RED" "test")
assert_not_empty "$output" "colorize should produce output"

# Every NEON_<COLOR> must have a matching NEON_<COLOR>_NUM (256-color index)
# so callers using gum's --border-foreground / --foreground "$NEON_*_NUM" work
# under `set -u`. Missing NUM siblings have caused unset-variable aborts in
# examples/openrgb_fix.sh (NEON_RED_NUM).
for color in PINK CYAN PURPLE YELLOW GREEN BLUE ORANGE RED; do
    assert_var_defined "NEON_${color}"
    assert_var_defined "NEON_${color}_NUM"
done

# Same parity for the basic ANSI palette (0-7). ui/layout/base.sh used to
# pass bare numeric literals "1", "2", "3", "6" to gum's --border-foreground;
# those are the standard 30+N / 90+N ANSI codes. Named constants make the
# theme tunable from one place.
assert_eq "0" "${ANSI_BLACK_NUM:-MISSING}" "ANSI_BLACK_NUM = 0"
assert_eq "1" "${ANSI_RED_NUM:-MISSING}" "ANSI_RED_NUM = 1"
assert_eq "2" "${ANSI_GREEN_NUM:-MISSING}" "ANSI_GREEN_NUM = 2"
assert_eq "3" "${ANSI_YELLOW_NUM:-MISSING}" "ANSI_YELLOW_NUM = 3"
assert_eq "4" "${ANSI_BLUE_NUM:-MISSING}" "ANSI_BLUE_NUM = 4"
assert_eq "5" "${ANSI_MAGENTA_NUM:-MISSING}" "ANSI_MAGENTA_NUM = 5"
assert_eq "6" "${ANSI_CYAN_NUM:-MISSING}" "ANSI_CYAN_NUM = 6"
assert_eq "7" "${ANSI_WHITE_NUM:-MISSING}" "ANSI_WHITE_NUM = 7"
