#!/usr/bin/env bash
# test_lspci.sh - Unit tests for lspci.sh

test_file_start "lspci.sh"

# Source the module
source "$PROJECT_DIR/lib/system/lspci.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_LSPCI_LOADED"

# Test that all functions exist
assert_function_exists "lspci_available"
assert_function_exists "lspci_get_device_name"
assert_function_exists "lspci_get_network_devices"
assert_function_exists "lspci_get_gpu_devices"
assert_function_exists "lspci_get_devices"

# Test lspci_available returns boolean (doesn't error)
if lspci_available; then
    echo "  ${GREEN}✓${RESET} lspci_available detected lspci"
else
    echo "  ${YELLOW}⚠${RESET} lspci_available: lspci not installed (skipping live tests)"
fi

# Test lspci_get_device_name with empty argument fails gracefully
result=$(lspci_get_device_name "")
assert_eq "" "$result" "lspci_get_device_name with empty arg returns empty"
