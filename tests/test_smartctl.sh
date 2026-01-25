#!/usr/bin/env bash
# test_smartctl.sh - Unit tests for smartctl.sh

test_file_start "smartctl.sh"

# Source the module
source "$PROJECT_DIR/lib/system/smartctl.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_SMARTCTL_LOADED"

# Test that all functions exist
assert_function_exists "smartctl_available"
assert_function_exists "nvme_available"
assert_function_exists "smartctl_get_temp"
assert_function_exists "nvme_get_temp"
assert_function_exists "smartctl_get_drive_temp"
assert_function_exists "smartctl_get_health"
assert_function_exists "nvme_get_health_pct"
assert_function_exists "smartctl_get_attributes"

# Test availability functions return boolean (don't error)
if smartctl_available; then
    echo "  ${GREEN}✓${RESET} smartctl_available detected smartctl"
else
    echo "  ${YELLOW}⚠${RESET} smartctl_available: smartctl not installed (skipping live tests)"
fi

if nvme_available; then
    echo "  ${GREEN}✓${RESET} nvme_available detected nvme-cli"
else
    echo "  ${YELLOW}⚠${RESET} nvme_available: nvme-cli not installed (skipping live tests)"
fi

# Test functions with empty argument fail gracefully
result=$(smartctl_get_temp "")
assert_eq "" "$result" "smartctl_get_temp with empty arg returns empty"

result=$(nvme_get_temp "")
assert_eq "" "$result" "nvme_get_temp with empty arg returns empty"

result=$(smartctl_get_drive_temp "")
assert_eq "" "$result" "smartctl_get_drive_temp with empty arg returns empty"
