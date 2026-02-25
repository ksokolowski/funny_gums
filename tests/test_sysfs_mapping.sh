#!/usr/bin/env bash
# test_sysfs_mapping.sh - Validates sysfs sensor mapping logic
# Uses a temporary directory to mock /sys/class/hwmon

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "sensors.sh (sysfs mapping)"

# Source colors for mock functions
source "$PROJECT_DIR/lib/core/term/colors.sh"

# Setup Mock Sysfs
MOCK_SYS=$(mktemp -d)
MOCK_HWMON="$MOCK_SYS/class/hwmon"
mkdir -p "$MOCK_HWMON"

cleanup() {
    rm -rf "$MOCK_SYS"
}
trap cleanup EXIT

# Helper: Create a mock sensor
# create_mock_sensor "hwmon0" "nvme" "0000:0d:00.0" "47900"
create_mock_sensor() {
    local id="$1"
    local name="$2"
    local pci="$3"
    local temp="$4"

    local dir="$MOCK_HWMON/$id"
    mkdir -p "$dir"
    echo "$name" >"$dir/name"
    echo "$temp" >"$dir/temp1_input"

    # Mock symlink to device pci path (device is the symlink itself)
    ln -s "../../../devices/pci0000:00/$pci" "$dir/device"
}

# 1. NVMe Drive 1 (0000:0d:00.0) -> 47.9°C
create_mock_sensor "hwmon0" "nvme" "0000:0d:00.0" "47900"

# 2. NVMe Drive 2 (0000:08:00.0) -> 55.5°C
create_mock_sensor "hwmon1" "nvme" "0000:08:00.0" "55500"

# 3. Network Card (0000:05:00.0 / r8169) -> 59.0°C
create_mock_sensor "hwmon2" "r8169" "0000:05:00.0" "59000"

# Source library
# We need to override the system path variable to point to our mock
SYSFS_HWMON_DIR="$MOCK_HWMON"
source "$PROJECT_DIR/lib/mod/hw/sensors.sh"

# Test Sysfs PCI Mapping

# Test NVMe 0d:00.0
temp=$(sensors_get_temp_by_pci_id "0000:0d:00.0")
assert_eq "47.9" "$temp" "NVMe 0d:00.0 temp should be 47.9"

# Test NVMe 08:00.0
temp=$(sensors_get_temp_by_pci_id "0000:08:00.0")
assert_eq "55.5" "$temp" "NVMe 08:00.0 temp should be 55.5"

# Test Network 05:00.0
temp=$(sensors_get_temp_by_pci_id "0000:05:00.0")
assert_eq "59.0" "$temp" "Network 05:00.0 temp should be 59.0"

# Test Non-existent
temp=$(sensors_get_temp_by_pci_id "0000:99:99.9")
((TESTS_RUN++))
if [[ -z "$temp" ]]; then
    echo "  ${GREEN}✓${RESET} Correctly returned empty for non-existent PCI ID"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Expected empty, got '$temp'"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("sysfs_mapping.sh: Should return empty for non-existent PCI ID")
fi
