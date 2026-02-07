#!/usr/bin/env bash
# test_sudo.sh - Unit tests for sudo.sh

test_file_start "sudo.sh"

# Source the module
source "$PROJECT_DIR/lib/core/sh/sudo.sh"

# Test that sudo functions exist
assert_function_exists "sudo_auth"
assert_function_exists "sudo_keepalive_start"
assert_function_exists "sudo_keepalive_stop"
assert_function_exists "sudo_setup"
assert_function_exists "sudo_cleanup"

# Test that SUDO_KEEPALIVE_PID variable exists
assert_var_defined "SUDO_KEEPALIVE_PID"
