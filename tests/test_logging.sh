#!/usr/bin/env bash
# test_logging.sh - Unit tests for logging.sh

test_file_start "logging.sh"

# Source the module
LOG_FILE="/tmp/test_gum_log_$$.log"
source "$PROJECT_DIR/lib/core/sh/logging.sh"

# Test that logging functions exist
assert_function_exists "log_init"
assert_function_exists "log_info"
assert_function_exists "log_warn"
assert_function_exists "log_error"
assert_function_exists "log_debug"
assert_function_exists "log_show"

# Test new logging functions
assert_function_exists "log_structured"
assert_function_exists "log_prefix"
assert_function_exists "log_fatal"

# Test log_init creates empty file
log_init "$LOG_FILE"
assert_success test -f "$LOG_FILE"

# Cleanup
rm -f "$LOG_FILE"
