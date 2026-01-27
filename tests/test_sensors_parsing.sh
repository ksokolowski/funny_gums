#!/usr/bin/env bash
# test_sensors_parsing.sh - Validates robust sensor parsing
# Mock data provided by user

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "sensors_parsing.sh"

# Source colors for mock functions
source "$PROJECT_DIR/lib/core/colors.sh"

# Mock sensors command
sensors() {
    cat <<EOF
spd5118-i2c-1-51
Adapter: SMBus PIIX4 adapter port 0 at 0b00
temp1:        +50.2°C  (low  =  +0.0°C, high = +55.0°C)
                       (crit low =  +0.0°C, crit = +85.0°C)

k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +46.6°C
Tccd1:        +40.8°C
Tccd2:        +40.0°C

nvme-pci-0d00
Adapter: PCI adapter
Composite:    +41.9°C  (low  =  -0.1°C, high = +74.8°C)
                       (crit = +79.8°C)
ERROR: Can't get value of subfeature temp3_min: I/O error
ERROR: Can't get value of subfeature temp3_max: I/O error
Sensor 2:     +41.9°C  (low  =  +0.0°C, high =  +0.0°C)
ERROR: Can't get value of subfeature temp4_min: I/O error
ERROR: Can't get value of subfeature temp4_max: I/O error
Sensor 3:     +47.9°C  (low  =  +0.0°C, high =  +0.0°C)
ERROR: Can't get value of subfeature temp5_min: I/O error
ERROR: Can't get value of subfeature temp5_max: I/O error
Sensor 4:     +41.9°C  (low  =  +0.0°C, high =  +0.0°C)
ERROR: Can't get value of subfeature temp6_min: I/O error
ERROR: Can't get value of subfeature temp6_max: I/O error
Sensor 5:     +41.9°C  (low  =  +0.0°C, high =  +0.0°C)
ERROR: Can't get value of subfeature temp7_min: I/O error
ERROR: Can't get value of subfeature temp7_max: I/O error
Sensor 6:     +36.9°C  (low  =  +0.0°C, high =  +0.0°C)

r8169_0_c00:00-mdio-0
Adapter: MDIO adapter
temp1:        +59.0°C  (high = +120.0°C)

spd5118-i2c-1-53
Adapter: SMBus PIIX4 adapter port 0 at 0b00
temp1:        +49.5°C  (low  =  +0.0°C, high = +55.0°C)
                       (crit low =  +0.0°C, crit = +85.0°C)

nvme-pci-0800
Adapter: PCI adapter
Composite:    +47.9°C  (low  = -273.1°C, high = +89.8°C)
                       (crit = +94.8°C)
Sensor 1:     +48.9°C  (low  = -273.1°C, high = +65261.8°C)
Sensor 2:     +38.9°C  (low  = -273.1°C, high = +65261.8°C)

nvme-pci-0200
Adapter: PCI adapter
Composite:    +53.9°C  (low  = -273.1°C, high = +65261.8°C)
                       (crit = +84.8°C)
Sensor 1:     +53.9°C  (low  = -273.1°C, high = +65261.8°C)
Sensor 2:     +54.9°C  (low  = -273.1°C, high = +65261.8°C)
EOF
}

# Mock check
sensors_available() { return 0; }

# Source library under test
source "$PROJECT_DIR/lib/system/sensors.sh"

# Test CPU Temp Selection (k10temp)
# Should prefer Tctl over Tccd1
cpu_temp=$(sensors_get_cpu_temp_smart)
assert_eq "46.6" "$cpu_temp" "CPU temp should be Tctl (46.6)"

# Test Filtering Anomalies
((TESTS_RUN++))
if _is_valid_temp "65261.8"; then
    echo "  ${RED}✗${RESET} Should reject 65261.8"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("sensors_parsing.sh: Should reject anomalous temp 65261.8")
else
    echo "  ${GREEN}✓${RESET} Rejected 65261.8"
    ((TESTS_PASSED++))
fi

((TESTS_RUN++))
if _is_valid_temp "-273.1"; then
    echo "  ${RED}✗${RESET} Should reject -273.1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("sensors_parsing.sh: Should reject anomalous temp -273.1")
else
    echo "  ${GREEN}✓${RESET} Rejected -273.1"
    ((TESTS_PASSED++))
fi

((TESTS_RUN++))
if _is_valid_temp "45.5"; then
    echo "  ${GREEN}✓${RESET} Accepted 45.5"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Should accept 45.5"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("sensors_parsing.sh: Should accept valid temp 45.5")
fi

# Test NVMe Temp Selection
# Should prefer Composite over Sensor 1 (which has outliers)
temp=$(sensors_get_temp_by_adapter "nvme-pci-0800")
assert_eq "47.9" "$temp" "NVMe 0800 temp should be Composite (47.9)"

temp=$(sensors_get_temp_by_adapter "nvme-pci-0200")
assert_eq "53.9" "$temp" "NVMe 0200 temp should be Composite (53.9)"

# Test RAM Temp Extraction
# Should find spd sensors
temps=$(sensors_get_ram_temps)
((TESTS_RUN++))
if [[ "$temps" == *"50.2"* ]] && [[ "$temps" == *"49.5"* ]]; then
     echo "  ${GREEN}✓${RESET} Found RAM temps (50.2, 49.5)"
     ((TESTS_PASSED++))
else
     echo "  ${RED}✗${RESET} Missing RAM temps (got: $temps)"
     ((TESTS_FAILED++))
     FAILED_TESTS+=("sensors_parsing.sh: Should extract RAM temps")
fi

# Test Network Temp Extraction
temps=$(sensors_get_network_temps)
((TESTS_RUN++))
if [[ "$temps" == *"59.0"* ]]; then
     echo "  ${GREEN}✓${RESET} Found Network temp (59.0)"
     ((TESTS_PASSED++))
else
     echo "  ${RED}✗${RESET} Missing Network temp (got: $temps)"
     ((TESTS_FAILED++))
     FAILED_TESTS+=("sensors_parsing.sh: Should extract network temp")
fi
