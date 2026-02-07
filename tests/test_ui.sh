#!/usr/bin/env bash
# test_ui.sh - Unit tests for ui.sh

set -uo pipefail

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "ui.sh"

# Source the module
source "$PROJECT_DIR/lib/ui/layout/ui.sh"

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

# Test new format functions
assert_function_exists "ui_format"
assert_function_exists "ui_format_code"
assert_function_exists "ui_format_emoji"
assert_function_exists "ui_format_template"

# Test new table functions
assert_function_exists "ui_table"
assert_function_exists "ui_table_file"
assert_function_exists "ui_table_columns"

# Test new pager functions
assert_function_exists "ui_pager"
assert_function_exists "ui_pager_numbered"
assert_function_exists "ui_pager_wrap"

# Test enhanced input functions
assert_function_exists "ui_input_ext"
assert_function_exists "ui_input_header"
assert_function_exists "ui_input_value"
assert_function_exists "ui_write_ext"

# Test enhanced choose functions
assert_function_exists "ui_choose_limit"
assert_function_exists "ui_choose_selected"
assert_function_exists "ui_choose_height"
assert_function_exists "ui_filter_header"
assert_function_exists "ui_dir"
assert_function_exists "ui_file_all"

# Test enhanced spin functions
assert_function_exists "ui_spin_type"
assert_function_exists "ui_spin_output"
