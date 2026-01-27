#!/usr/bin/env bash
# test_sensors_parsing.sh - Validates robust sensor parsing
# Mock data provided by user

source lib/core/colors.sh

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

echo "━━━ Testing: CPU Temp Selection (k10temp) ━━━"
# Should prefer Tctl over Tccd1
cpu_temp=$(sensors_get_cpu_temp_smart)
echo "Got CPU Temp: $cpu_temp"
assert_eq "$cpu_temp" "46.6"

echo "━━━ Testing: Filtering Anomalies ━━━"
# Validate filter function directly
if _is_valid_temp "65261.8"; then
    echo -e "${RED}  ✗ Should reject 65261.8${RESET}"
    FAILED=1
else
    echo -e "${GREEN}  ✓ Rejected 65261.8${RESET}"
fi
if _is_valid_temp "-273.1"; then
    echo -e "${RED}  ✗ Should reject -273.1${RESET}"
    FAILED=1
else
    echo -e "${GREEN}  ✓ Rejected -273.1${RESET}"
fi
if _is_valid_temp "45.5"; then
    echo -e "${GREEN}  ✓ Accepted 45.5${RESET}"
else
    echo -e "${RED}  ✗ Should accept 45.5${RESET}"
    FAILED=1
fi

echo "━━━ Testing: NVMe Temp Selection ━━━"
# Should prefer Composite over Sensor 1 (which has outliers)
# Mocking a specific call to a drive sensor logic we will build
temp=$(sensors_get_temp_by_adapter "nvme-pci-0800")
echo "Got NVMe 0800 Temp: $temp"
assert_eq "$temp" "47.9"

temp=$(sensors_get_temp_by_adapter "nvme-pci-0200")
echo "Got NVMe 0200 Temp: $temp"
assert_eq "$temp" "53.9"

echo "━━━ Testing: RAM Temp Extraction ━━━"
# Should find spd sensors
temps=$(sensors_get_ram_temps)
echo "Got RAM Temps:"
echo "$temps"
# Expecting 50.2 and 49.5
if [[ "$temps" == *"50.2"* ]] && [[ "$temps" == *"49.5"* ]]; then
     echo -e "${GREEN}  ✓ Found RAM temps${RESET}"
else
     echo -e "${RED}  ✗ Missing RAM temps${RESET}"
     FAILED=1
fi

echo "━━━ Testing: Network Temp Extraction ━━━"
temps=$(sensors_get_network_temps)
echo "Got Net Temps:"
echo "$temps"
if [[ "$temps" == *"59.0"* ]]; then
     echo -e "${GREEN}  ✓ Found Network temp${RESET}"
else
     echo -e "${RED}  ✗ Missing Network temp${RESET}"
     FAILED=1
fi

exit ${FAILED:-0}
