#!/usr/bin/env bash
# test_spinner.sh - Unit tests for spinner.sh

test_file_start "spinner.sh"

# Source the module
source "$PROJECT_DIR/lib/ui/widgets/spinner.sh"

# Test that spinner functions exist
assert_function_exists "spinner_set"
assert_function_exists "spinner_custom"
assert_function_exists "spinner_reset"
assert_function_exists "spinner_frame"
assert_function_exists "spinner_next"
assert_function_exists "spinner_tick"

# Test default spinner frames
assert_var_defined "SPINNER_FRAMES"
assert_not_empty "${SPINNER_FRAMES[*]}" "SPINNER_FRAMES should not be empty"

# Test spinner_frame returns a frame
frame=$(spinner_frame)
assert_not_empty "$frame" "spinner_frame should return a frame"

# Test spinner_reset
SPINNER_IDX=5
spinner_reset
assert_eq "0" "$SPINNER_IDX" "spinner_reset should set SPINNER_IDX to 0"

# Test spinner_next increments index
SPINNER_IDX=0
spinner_next
assert_eq "1" "$SPINNER_IDX" "spinner_next should increment SPINNER_IDX"

# Test spinner_set changes frames
spinner_set MOON
assert_eq "🌑" "${SPINNER_FRAMES[0]}" "spinner_set MOON should set first frame to moon"

# Reset to default
spinner_set RGB
assert_eq "🔴" "${SPINNER_FRAMES[0]}" "spinner_set RGB should set first frame to red circle"
