#!/usr/bin/env bash
# test_nvidia.sh - Unit tests for nvidia.sh

test_file_start "nvidia.sh"

# Source the module
source "$PROJECT_DIR/lib/mod/hw/nvidia.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_NVIDIA_LOADED"

# Test that all functions exist
assert_function_exists "nvidia_available"
assert_function_exists "nvidia_get_temp"
assert_function_exists "nvidia_get_utilization"
assert_function_exists "nvidia_get_memory_usage"
assert_function_exists "nvidia_get_power_draw"
assert_function_exists "nvidia_get_fan_speed"
assert_function_exists "nvidia_get_gpu_name"
assert_function_exists "nvidia_get_clocks"
assert_function_exists "nvidia_get_driver_version"

# Test nvidia_available returns boolean (doesn't error)
if nvidia_available; then
    echo "  ${GREEN}✓${RESET} nvidia_available detected nvidia-smi"

    # If NVIDIA is available, test that functions don't error
    assert_success nvidia_get_temp "nvidia_get_temp executes without error"
    assert_success nvidia_get_gpu_name "nvidia_get_gpu_name executes without error"
else
    echo "  ${YELLOW}⚠${RESET} nvidia_available: nvidia-smi not installed (skipping live tests)"
fi
