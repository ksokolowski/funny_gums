#!/usr/bin/env bash
# test_dashboard.sh - Unit tests for dashboard.sh

test_file_start "dashboard.sh"

# Source the module
source "$PROJECT_DIR/lib/app/dashboard.sh"

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

# Title icon — parameterised so callers can replace or suppress the hardcoded
# wrench. Default preserves prior behaviour for back-compat.
dashboard_init "Default Icon Test"
assert_eq "🔧" "${DASHBOARD_TITLE_ICON-NOT_DEFINED}" "dashboard_init default icon is the wrench"

dashboard_init "Custom Icon Test" "🚀"
assert_eq "🚀" "${DASHBOARD_TITLE_ICON-NOT_DEFINED}" "dashboard_init accepts an explicit icon override"

dashboard_init "No Icon Test" ""
assert_eq "" "${DASHBOARD_TITLE_ICON-NOT_DEFINED}" "dashboard_init accepts empty string to suppress the icon"

# Reset to default for any later code that depends on it
dashboard_init "Test Dashboard"

# Layout derivation. `steps_start` (row of first step inside the gum frame)
# and the spinner column previously hardcoded 5 and 4 — both implicitly
# agreed with --padding "1 2". Promote the padding values and derive the
# rest, so a caller who bumps the padding doesn't desync the spinner glyph.
DASHBOARD_PADDING_TOP=1
DASHBOARD_PADDING_LEFT=2
assert_eq "5" "$(_dashboard_steps_start)" "default padding → first step at row 5"
assert_eq "4" "$(_dashboard_spinner_col)" "default padding → spinner glyph at col 4"

DASHBOARD_PADDING_TOP=2
DASHBOARD_PADDING_LEFT=3
assert_eq "6" "$(_dashboard_steps_start)" "padding top=2 → first step at row 6"
assert_eq "5" "$(_dashboard_spinner_col)" "padding left=3 → spinner glyph at col 5"

# Restore defaults
DASHBOARD_PADDING_TOP=1
DASHBOARD_PADDING_LEFT=2
