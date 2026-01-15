#!/usr/bin/env bash
# test_ui.sh - Unit tests for ui.sh

test_file_start "ui.sh"

# Source the module
source "$PROJECT_DIR/lib/ui.sh"

# Test that UI functions exist
assert_function_exists "ui_box"
assert_function_exists "ui_box_double"
assert_function_exists "ui_success"
assert_function_exists "ui_error"
assert_function_exists "ui_warn"
assert_function_exists "ui_info"
assert_function_exists "ui_confirm"
assert_function_exists "ui_choose"
assert_function_exists "ui_choose_multi"
assert_function_exists "ui_input"
assert_function_exists "ui_password"
assert_function_exists "ui_filter"
assert_function_exists "ui_file"
assert_function_exists "ui_spin"
assert_function_exists "ui_join_h"
assert_function_exists "ui_join_v"
