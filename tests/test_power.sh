#!/usr/bin/env bash
# test_power.sh - Unit tests for power.sh

test_file_start "power.sh"

# Source the module
source "$PROJECT_DIR/lib/mod/os/power.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_POWER_LOADED"

# Test that all functions exist
assert_function_exists "power_available"
assert_function_exists "power_on_ac"
assert_function_exists "power_has_battery"
assert_function_exists "power_get_battery_percent"
assert_function_exists "power_get_battery_status"
assert_function_exists "power_get_battery_time"
assert_function_exists "power_get_battery_health"
assert_function_exists "power_get_thermal_zones"
assert_function_exists "power_get_battery_info"

# Test internal helpers exist
assert_function_exists "_power_acpi_available"
assert_function_exists "_power_upower_available"

# Test availability function returns boolean (doesn't error)
if power_available; then
    echo "  ${GREEN}✓${RESET} power_available detected acpi or upower"
else
    echo "  ${YELLOW}⚠${RESET} power_available: neither acpi nor upower installed (skipping live tests)"
fi

# Test individual tool availability
if _power_acpi_available; then
    echo "  ${GREEN}✓${RESET} _power_acpi_available detected acpi"
else
    echo "  ${YELLOW}⚠${RESET} _power_acpi_available: acpi not installed"
fi

if _power_upower_available; then
    echo "  ${GREEN}✓${RESET} _power_upower_available detected upower"
else
    echo "  ${YELLOW}⚠${RESET} _power_upower_available: upower not installed"
fi

# Test battery detection
if power_available; then
    if power_has_battery; then
        echo "  ${GREEN}✓${RESET} power_has_battery detected battery"

        # Test battery percentage
        result=$(power_get_battery_percent)
        if [[ -n "$result" && "$result" =~ ^[0-9]+$ ]]; then
            echo "  ${GREEN}✓${RESET} power_get_battery_percent returned valid percentage: $result%"
        else
            echo "  ${YELLOW}⚠${RESET} power_get_battery_percent returned: $result"
        fi

        # Test battery status
        result=$(power_get_battery_status)
        if [[ -n "$result" ]]; then
            echo "  ${GREEN}✓${RESET} power_get_battery_status returned: $result"
        else
            echo "  ${YELLOW}⚠${RESET} power_get_battery_status returned empty"
        fi

        # Test combined info
        result=$(power_get_battery_info)
        if [[ "$result" == *"|"* ]]; then
            echo "  ${GREEN}✓${RESET} power_get_battery_info returned expected format"
        else
            echo "  ${YELLOW}⚠${RESET} power_get_battery_info returned: $result"
        fi
    else
        echo "  ${YELLOW}⚠${RESET} power_has_battery: no battery detected (desktop system?)"
    fi

    # Test AC power detection
    if power_on_ac; then
        echo "  ${GREEN}✓${RESET} power_on_ac detected AC power"
    else
        echo "  ${GREEN}✓${RESET} power_on_ac detected battery power"
    fi

    # Test thermal zones
    result=$(power_get_thermal_zones)
    if [[ -n "$result" ]]; then
        zone_count=$(echo "$result" | wc -l)
        echo "  ${GREEN}✓${RESET} power_get_thermal_zones found $zone_count thermal zone(s)"
    else
        echo "  ${YELLOW}⚠${RESET} power_get_thermal_zones returned empty (no thermal zones?)"
    fi
fi

# Test graceful failure when no battery
if power_available && ! power_has_battery; then
    result=$(power_get_battery_percent)
    assert_eq "" "$result" "power_get_battery_percent returns empty when no battery"

    result=$(power_get_battery_status)
    assert_eq "" "$result" "power_get_battery_status returns empty when no battery"

    result=$(power_get_battery_info)
    assert_eq "" "$result" "power_get_battery_info returns empty when no battery"
fi
