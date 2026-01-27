#!/usr/bin/env bash
# test_dmidecode.sh - Unit tests for dmidecode.sh

test_file_start "dmidecode.sh"

# Source the module
source "$PROJECT_DIR/lib/system/dmidecode.sh"

# Test that guard variable is set
assert_var_defined "_SYSTEM_DMIDECODE_LOADED"

# Test that all functions exist
assert_function_exists "dmidecode_available"
assert_function_exists "dmidecode_get_bios_vendor"
assert_function_exists "dmidecode_get_bios_version"
assert_function_exists "dmidecode_get_bios_date"
assert_function_exists "dmidecode_get_board_name"
assert_function_exists "dmidecode_get_board_vendor"
assert_function_exists "dmidecode_get_system_name"
assert_function_exists "dmidecode_get_system_vendor"
assert_function_exists "dmidecode_get_system_serial"
assert_function_exists "dmidecode_get_memory_slots"
assert_function_exists "dmidecode_get_memory_info"
assert_function_exists "dmidecode_get_chassis_type"
assert_function_exists "dmidecode_get_processor_info"
assert_function_exists "dmidecode_get_bios_info"
assert_function_exists "dmidecode_get_board_info"

# Test availability function returns boolean (doesn't error)
if dmidecode_available; then
    echo "  ${GREEN}✓${RESET} dmidecode_available detected dmidecode"
else
    echo "  ${YELLOW}⚠${RESET} dmidecode_available: dmidecode not installed (skipping live tests)"
fi

# Test functions return without error when tool not available
# (They should return empty or fail gracefully)
if ! dmidecode_available; then
    result=$(dmidecode_get_bios_vendor 2>/dev/null)
    assert_eq "" "$result" "dmidecode_get_bios_vendor returns empty when tool unavailable"

    result=$(dmidecode_get_board_name 2>/dev/null)
    assert_eq "" "$result" "dmidecode_get_board_name returns empty when tool unavailable"
fi

# Test combined info functions exist and are callable
if dmidecode_available; then
    # These require sudo, so we just verify they don't crash
    result=$(dmidecode_get_bios_info 2>/dev/null || echo "requires_sudo")
    if [[ "$result" == "requires_sudo" || "$result" == *"|"* ]]; then
        echo "  ${GREEN}✓${RESET} dmidecode_get_bios_info returns expected format or requires sudo"
    else
        echo "  ${YELLOW}⚠${RESET} dmidecode_get_bios_info returned unexpected: $result"
    fi

    result=$(dmidecode_get_board_info 2>/dev/null || echo "requires_sudo")
    if [[ "$result" == "requires_sudo" || "$result" == *"|"* ]]; then
        echo "  ${GREEN}✓${RESET} dmidecode_get_board_info returns expected format or requires sudo"
    else
        echo "  ${YELLOW}⚠${RESET} dmidecode_get_board_info returned unexpected: $result"
    fi
fi

# Test Configured Memory Speed parsing (Mock)
test_memory_speed_parsing() {
    # Mock sudo to return specific dmidecode output
    sudo() {
        if [[ "$1" == "dmidecode" && "$2" == "-t" && "$3" == "memory" ]]; then
           cat <<EOF
Memory Device
	Array Handle: 0x0001
	Error Information Handle: Not Provided
	Total Width: 64 bits
	Data Width: 64 bits
	Size: 32 GB
	Form Factor: DIMM
	Set: None
	Locator: DIMM 1
	Bank Locator: P0 CHANNEL B
	Type: DDR5
	Type Detail: Synchronous Unbuffered (Unregistered)
	Speed: 4800 MT/s
	Manufacturer: Corsair
	Serial Number: 00000000
	Asset Tag: Not Specified
	Part Number: CMK64GX5M2B6000C40
	Rank: 2
	Configured Memory Speed: 6000 MT/s
	Minimum Voltage: 1.1 V
	Maximum Voltage: 1.1 V
	Configured Voltage: 1.1 V
EOF
        else
           # Fallback requires capturing original behavior or just failing for this mock
           return 1
        fi
    }
    
    # Mock available check to force execution
    dmidecode_available() { return 0; }
    
    local result
    result=$(dmidecode_get_memory_info)
    
    # Expected: includes "6000 MT/s"
    # Format: slot|channel|size|type|speed|mfr|configured_speed
    if echo "$result" | grep -q "6000 MT/s"; then
        echo "  ${GREEN}✓${RESET} dmidecode_get_memory_info parses Configured Memory Speed"
    else
        echo "  ${RED}✗${RESET} Failed to parse Configured Speed. Result: $result"
        # Manually signal failure since we can't easily increment global counter without scope issues
        exit 1
    fi
}

test_memory_speed_parsing
