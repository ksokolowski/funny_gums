#!/usr/bin/env bash
# test_runner.sh - Unit tests for runner.sh

test_file_start "runner.sh"

# Source the module (requires LOG_FILE)
LOG_FILE="/tmp/test_runner_$$.log"
source "$PROJECT_DIR/lib/runner.sh"

# Test that runner functions exist
assert_function_exists "runner_cleanup"
assert_function_exists "runner_exec"

# Test that RUNNER_CMD_PID variable exists
assert_var_defined "RUNNER_CMD_PID"

# Cleanup
rm -f "$LOG_FILE"
