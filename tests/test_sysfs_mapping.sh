#!/usr/bin/env bash
# test_sysfs_mapping.sh - Validates sysfs sensor mapping logic
# Uses a temporary directory to mock /sys/class/hwmon

source lib/core/colors.sh

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
    echo "$name" > "$dir/name"
    echo "$temp" > "$dir/temp1_input"
    
    # Mock symlink to device pci path (device is the symlink itself)
    ln -s "../../../devices/pci0000:00/$pci" "$dir/device"
    # We can just store the pci id in a file for the test to read if we mock the resolver, 
    # but let's try to mock the real readlink behavior if possible or just put a file we can read.
    # Ideally, we mock the function `resolve_pci_path` to return our pci string.
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
source lib/system/sensors.sh

# Helper assertions
assert_eq() {
    if [[ "$1" == "$2" ]]; then
        echo -e "${GREEN}  ✓ Expected: '$2'${RESET}"
    else
        echo -e "${RED}  ✗ Expected: '$2', Got: '$1'${RESET}"
        FAILED=1
    fi
}

echo "━━━ Testing: Sysfs PCI Mapping ━━━"

echo "Looking up NVMe 0d:00.0..."
# Function we haven't written yet
temp=$(sensors_get_temp_by_pci_id "0000:0d:00.0")
echo "Result: $temp"
assert_eq "$temp" "47.9"

echo "Looking up NVMe 08:00.0..."
temp=$(sensors_get_temp_by_pci_id "0000:08:00.0")
echo "Result: $temp"
assert_eq "$temp" "55.5"

echo "Looking up Network 05:00.0..."
temp=$(sensors_get_temp_by_pci_id "0000:05:00.0")
echo "Result: $temp"
assert_eq "$temp" "59.0"

echo "Looking up Non-existent..."
temp=$(sensors_get_temp_by_pci_id "0000:99:99.9")
if [[ -z "$temp" ]]; then
    echo -e "${GREEN}  ✓ Correctly returned empty${RESET}"
else
    echo -e "${RED}  ✗ Expected empty, got '$temp'${RESET}"
    FAILED=1
fi

exit ${FAILED:-0}
