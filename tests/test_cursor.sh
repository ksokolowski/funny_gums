#!/usr/bin/env bash
# test_cursor.sh - Unit tests for cursor.sh

test_file_start "cursor.sh"

# Source the module
source "$PROJECT_DIR/lib/cursor.sh"

# Test that cursor functions exist
assert_function_exists "cursor_hide"
assert_function_exists "cursor_show"
assert_function_exists "cursor_save"
assert_function_exists "cursor_restore"
assert_function_exists "cursor_up"
assert_function_exists "cursor_down"
assert_function_exists "cursor_left"
assert_function_exists "cursor_right"
assert_function_exists "cursor_column"
assert_function_exists "cursor_goto"
assert_function_exists "clear_to_end"
assert_function_exists "clear_line"
