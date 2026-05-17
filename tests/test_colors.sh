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
