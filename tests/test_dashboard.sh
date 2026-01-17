#!/usr/bin/env bash
# test_dashboard.sh - Unit tests for dashboard.sh

test_file_start "dashboard.sh"

# Source the module
source "$PROJECT_DIR/lib/dashboard/dashboard.sh"

# Test that dashboard functions exist
assert_function_exists "dashboard_init"
assert_function_exists "dashboard_add_step"
assert_function_exists "dashboard_enable_step"
assert_function_exists "dashboard_enabled_count"
assert_function_exists "dashboard_draw"
assert_function_exists "dashboard_update_spinner"
assert_function_exists "dashboard_step_start"
assert_function_exists "dashboard_step_done"
assert_function_exists "dashboard_step_skip"
assert_function_exists "dashboard_has_failure"

# Test dashboard_init
dashboard_init "Test Dashboard"
assert_eq "Test Dashboard" "$DASHBOARD_TITLE" "dashboard_init should set title"
assert_eq "0" "${#DASHBOARD_STEPS[@]}" "dashboard_init should clear steps"

# Test dashboard_add_step
dashboard_add_step "Step 1"
dashboard_add_step "Step 2"
assert_eq "2" "${#DASHBOARD_STEPS[@]}" "dashboard_add_step should add steps"
assert_eq "Step 1" "${DASHBOARD_STEPS[0]}" "First step should be 'Step 1'"
assert_eq "Step 2" "${DASHBOARD_STEPS[1]}" "Second step should be 'Step 2'"

# Test dashboard_enabled_count
count=$(dashboard_enabled_count)
assert_eq "2" "$count" "dashboard_enabled_count should return 2"

# Test dashboard_enable_step
dashboard_enable_step 0 false
count=$(dashboard_enabled_count)
assert_eq "1" "$count" "dashboard_enabled_count should return 1 after disabling"

# Test dashboard_has_failure
DASHBOARD_HAS_FAILURE=false
if dashboard_has_failure; then
    result="true"
else
    result="false"
fi
assert_eq "false" "$result" "dashboard_has_failure should return false initially"
