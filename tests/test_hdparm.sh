#!/usr/bin/env bash
# test_hdparm.sh - Unit tests for hdparm.sh

test_file_start "hdparm.sh"

# Source the module
source "$PROJECT_DIR/lib/system/hdparm.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_HDPARM_LOADED"

# Test that all functions exist
assert_function_exists "hdparm_available"
assert_function_exists "hdparm_get_model"
assert_function_exists "hdparm_get_serial"
assert_function_exists "hdparm_get_firmware"
assert_function_exists "hdparm_get_geometry"
assert_function_exists "hdparm_get_readonly"
assert_function_exists "hdparm_is_sleeping"
assert_function_exists "hdparm_get_drive_info"
assert_function_exists "hdparm_get_transfer_mode"

# Test availability function returns boolean (doesn't error)
if hdparm_available; then
    echo "  ${GREEN}✓${RESET} hdparm_available detected hdparm"
else
    echo "  ${YELLOW}⚠${RESET} hdparm_available: hdparm not installed (skipping live tests)"
fi

# Test functions with empty argument fail gracefully
result=$(hdparm_get_model "")
assert_eq "" "$result" "hdparm_get_model with empty arg returns empty"

result=$(hdparm_get_serial "")
assert_eq "" "$result" "hdparm_get_serial with empty arg returns empty"

result=$(hdparm_get_firmware "")
assert_eq "" "$result" "hdparm_get_firmware with empty arg returns empty"

result=$(hdparm_get_geometry "")
assert_eq "" "$result" "hdparm_get_geometry with empty arg returns empty"

result=$(hdparm_get_readonly "")
assert_eq "" "$result" "hdparm_get_readonly with empty arg returns empty"

result=$(hdparm_get_drive_info "")
assert_eq "" "$result" "hdparm_get_drive_info with empty arg returns empty"

result=$(hdparm_get_transfer_mode "")
assert_eq "" "$result" "hdparm_get_transfer_mode with empty arg returns empty"

# Test is_sleeping with empty arg returns failure
if hdparm_is_sleeping ""; then
    echo "  ${RED}✗${RESET} hdparm_is_sleeping should fail with empty arg"
else
    echo "  ${GREEN}✓${RESET} hdparm_is_sleeping fails gracefully with empty arg"
fi
