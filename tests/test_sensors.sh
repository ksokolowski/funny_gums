#!/usr/bin/env bash
# test_sensors.sh - Unit tests for sensors.sh

test_file_start "sensors.sh"

# Source the module
source "$PROJECT_DIR/lib/mod/hw/sensors.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_SENSORS_LOADED"

# Test that all functions exist
assert_function_exists "sensors_available"
assert_function_exists "sensors_get_cpu_temp"
assert_function_exists "sensors_get_amd_gpu_temp"
assert_function_exists "sensors_get_amd_edge_temp"
assert_function_exists "sensors_get_amd_junction_temp"
assert_function_exists "sensors_get_all_temps"
assert_function_exists "sensors_get_fan_speeds"

# Test sensors_available returns boolean (doesn't error)
if sensors_available; then
    echo "  ${GREEN}✓${RESET} sensors_available detected lm-sensors"
else
    echo "  ${YELLOW}⚠${RESET} sensors_available: lm-sensors not installed (skipping live tests)"
fi
