#!/usr/bin/env bash
# test_runner.sh - Unit tests for runner.sh

test_file_start "runner.sh"

# Source the module (requires LOG_FILE)
LOG_FILE="/tmp/test_runner_$$.log"
source "$PROJECT_DIR/lib/app/runner.sh"

# Test that runner functions exist
assert_function_exists "runner_cleanup"
assert_function_exists "runner_exec"

# Test that RUNNER_CMD_PID variable exists
assert_var_defined "RUNNER_CMD_PID"

# Regression: runner_exec must NOT write to stdout while a step runs, even on
# failure. The dashboard owns the terminal; any leaked line desynchronises the
# cursor-up/clear arithmetic in dashboard_draw and produces an orphan "╭──╮"
# border on the next redraw (observed when /dev/sda was removed and the disk
# step failed in examples/openrgb_fix.sh). Failure detail belongs in LOG_FILE,
# not stdout.
if command -v gum >/dev/null 2>&1; then
    DASHBOARD_QUIET=true
    dashboard_init "test-dashboard"
    dashboard_add_step "step that will fail"
    leaked=$(runner_exec 0 false 2>/dev/null)
    assert_eq "" "$leaked" "runner_exec must not write to stdout on failure (would corrupt dashboard redraw)"
fi

# Cleanup
rm -f "$LOG_FILE"
