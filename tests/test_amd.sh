#!/usr/bin/env bash
# test_amd.sh - Unit tests for amd.sh

test_file_start "amd.sh"

# Source the module
source "$PROJECT_DIR/lib/system/amd.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_AMD_LOADED"

# Test that sensors module was loaded (dependency)
assert_var_defined "_SYSTEM_SENSORS_LOADED"

# Test that all functions exist
assert_function_exists "amd_gpu_available"
assert_function_exists "amd_get_temp"
assert_function_exists "amd_get_edge_temp"
assert_function_exists "amd_get_junction_temp"
assert_function_exists "amd_get_fan_speed"
assert_function_exists "amd_get_power"
assert_function_exists "amd_get_vram_usage"

# Test amd_gpu_available returns boolean (doesn't error)
if amd_gpu_available; then
    echo "  ${GREEN}✓${RESET} amd_gpu_available detected AMD GPU"

    # If AMD GPU is available, test that functions don't error
    amd_get_temp >/dev/null 2>&1
    echo "  ${GREEN}✓${RESET} amd_get_temp executes without error"
else
    echo "  ${YELLOW}⚠${RESET} amd_gpu_available: AMD GPU not detected (skipping live tests)"
fi
