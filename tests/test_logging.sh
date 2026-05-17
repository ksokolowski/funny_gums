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

# Test additional logging functions
assert_function_exists "log_silent"
assert_function_exists "log_time"
assert_function_exists "log_structured"
assert_function_exists "log_prefix"
assert_function_exists "log_fatal"

# Test log_init creates empty file
log_init "$LOG_FILE"
assert_success test -f "$LOG_FILE"

# The LOGGING_QUIET contract: when a TUI component (dashboard, custom screen)
# owns the terminal, it sets LOGGING_QUIET=true. All console-emitting log
# functions must then write to LOG_FILE only — otherwise their `tee` to stdout
# scrambles the cursor accounting and produces orphan UI rows.
# (See the openrgb_fix.sh dashboard-redraw regression in 1.1.x for the
# original symptom this contract prevents.)
if command -v gum >/dev/null 2>&1; then
    log_init "$LOG_FILE"

    LOGGING_QUIET=true
    leaked_info=$(log_info "smoke info" 2>/dev/null)
    leaked_warn=$(log_warn "smoke warn" 2>/dev/null)
    leaked_error=$(log_error "smoke error" 2>/dev/null)
    VERBOSE=true
    leaked_debug=$(log_debug "smoke debug" 2>/dev/null)
    VERBOSE=false
    leaked_struct=$(log_structured info "smoke" k v 2>/dev/null)
    LOGGING_QUIET=false

    assert_eq "" "$leaked_info" "log_info honours LOGGING_QUIET (no stdout leak)"
    assert_eq "" "$leaked_warn" "log_warn honours LOGGING_QUIET (no stdout leak)"
    assert_eq "" "$leaked_error" "log_error honours LOGGING_QUIET (no stdout leak)"
    assert_eq "" "$leaked_debug" "log_debug honours LOGGING_QUIET (no stdout leak, even with VERBOSE=true)"
    assert_eq "" "$leaked_struct" "log_structured honours LOGGING_QUIET (no stdout leak)"

    # The file side must still receive content — quiet means "don't echo",
    # not "don't log".
    assert_success grep -q "smoke error" "$LOG_FILE"

    # And LOGGING_QUIET=false restores the prior tee-to-stdout behaviour.
    visible=$(log_info "audible" 2>/dev/null)
    assert_contains "audible" "$visible" "log_info echoes to stdout when LOGGING_QUIET=false"
fi

# Cleanup
rm -f "$LOG_FILE"
