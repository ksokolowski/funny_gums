#!/usr/bin/env bash
# test_astral.sh - Unit tests for the astral12vhpwr hwmon module

test_file_start "astral.sh"

# Mock a minimal astral12vhpwr hwmon device via SYSFS_HWMON_DIR.
MOCK_SYS=$(mktemp -d)
MOCK_HWMON="$MOCK_SYS/hwmon0"
mkdir -p "$MOCK_HWMON"

echo "astral12vhpwr" >"$MOCK_HWMON/name"
echo "200" >"$MOCK_HWMON/update_interval"
# Per-pin currents (mA): balanced idle-ish frame
echo "660" >"$MOCK_HWMON/curr1_input"
echo "680" >"$MOCK_HWMON/curr2_input"
echo "640" >"$MOCK_HWMON/curr3_input"
echo "700" >"$MOCK_HWMON/curr4_input"
echo "620" >"$MOCK_HWMON/curr5_input"
echo "720" >"$MOCK_HWMON/curr6_input"
# Per-pin voltages (mV): healthy 12.18 / 12.18 / 12.18 / 12.16 / 12.18 / 12.18 V
echo "12180" >"$MOCK_HWMON/in0_input"
echo "12180" >"$MOCK_HWMON/in1_input"
echo "12180" >"$MOCK_HWMON/in2_input"
echo "12160" >"$MOCK_HWMON/in3_input"
echo "12180" >"$MOCK_HWMON/in4_input"
echo "12180" >"$MOCK_HWMON/in5_input"

export SYSFS_HWMON_DIR="$MOCK_SYS"

# Source the module
source "$PROJECT_DIR/lib/mod/hw/astral.sh"

assert_var_defined "_SYSTEM_ASTRAL_LOADED"

# API surface
assert_function_exists "astral_available"
assert_function_exists "astral_get_update_interval_ms"
assert_function_exists "astral_get_pin_current_ma"
assert_function_exists "astral_get_pin_voltage_mv"
assert_function_exists "astral_get_all_currents_ma"
assert_function_exists "astral_get_all_voltages_mv"
assert_function_exists "astral_get_total_current_ma"
assert_function_exists "astral_get_max_current_ma"
assert_function_exists "astral_get_balance_pct"
assert_function_exists "astral_get_connector_power_w"
assert_function_exists "astral_pin_current_status"
assert_function_exists "astral_pin_voltage_status"
assert_function_exists "astral_balance_status"
assert_function_exists "astral_classify_current_ma"
assert_function_exists "astral_classify_voltage_mv"
assert_function_exists "astral_classify_balance_pct"

# Discovery
assert_success astral_available "astral12vhpwr hwmon device should be discovered"
assert_eq "200" "$(astral_get_update_interval_ms)" "update_interval should be read"

# Raw per-pin reads
assert_eq "660" "$(astral_get_pin_current_ma 1)" "current of pin 1"
assert_eq "720" "$(astral_get_pin_current_ma 6)" "current of pin 6"
assert_eq "12180" "$(astral_get_pin_voltage_mv 1)" "voltage of pin 1 (in0)"
assert_eq "12160" "$(astral_get_pin_voltage_mv 4)" "voltage of pin 4 (in3)"

# Out-of-range pins must fail cleanly
assert_fails astral_get_pin_current_ma 0 "pin 0 is out of range"
assert_fails astral_get_pin_current_ma 7 "pin 7 is out of range"
assert_fails astral_get_pin_voltage_mv 0 "voltage of pin 0 is out of range"

# Aggregates
assert_eq "660 680 640 700 620 720" "$(astral_get_all_currents_ma)" "all currents"
assert_eq "12180 12180 12180 12160 12180 12180" "$(astral_get_all_voltages_mv)" "all voltages"
assert_eq "4020" "$(astral_get_total_current_ma)" "total connector current"
assert_eq "720" "$(astral_get_max_current_ma)" "heaviest pin"
assert_eq "86" "$(astral_get_balance_pct)" "balanced frame -> high ratio"
assert_eq "48.9" "$(astral_get_connector_power_w)" "connector power"

# Statuses on the healthy frame
assert_eq "ok" "$(astral_pin_current_status 1)" "healthy pin current status"
assert_eq "ok" "$(astral_pin_voltage_status 1)" "healthy pin voltage status"
assert_eq "ok" "$(astral_balance_status)" "balanced connector status"

# Threshold semantics: per-pin current warn/crit (9200 / 9500 mA)
echo "9300" >"$MOCK_HWMON/curr1_input"
assert_eq "warn" "$(astral_pin_current_status 1)" "pin at 9300 mA should warn"
echo "9600" >"$MOCK_HWMON/curr1_input"
assert_eq "crit" "$(astral_pin_current_status 1)" "pin at 9600 mA should be critical"
echo "660" >"$MOCK_HWMON/curr1_input"

# Pure value classifiers agree with their sysfs-reading siblings
assert_eq "ok" "$(astral_classify_current_ma 600)" "classify 600 mA"
assert_eq "warn" "$(astral_classify_current_ma 9300)" "classify 9300 mA"
assert_eq "crit" "$(astral_classify_current_ma 9600)" "classify 9600 mA"
assert_eq "ok" "$(astral_classify_voltage_mv 12100)" "classify 12.1 V"
assert_eq "warn" "$(astral_classify_voltage_mv 11200)" "classify 11.2 V"
assert_eq "crit" "$(astral_classify_voltage_mv 10600)" "classify 10.6 V"
assert_eq "ok" "$(astral_classify_balance_pct 71)" "classify 71% balance"
assert_eq "warn" "$(astral_classify_balance_pct 64)" "classify 64% balance"
assert_eq "crit" "$(astral_classify_balance_pct 55)" "classify 55% balance"

# Voltage sag semantics: below 11400 is warn, below 11000 is crit
echo "11200" >"$MOCK_HWMON/in0_input"
assert_eq "warn" "$(astral_pin_voltage_status 1)" "11.2 V should warn"
echo "10600" >"$MOCK_HWMON/in0_input"
assert_eq "crit" "$(astral_pin_voltage_status 1)" "10.6 V should be critical"
echo "12180" >"$MOCK_HWMON/in0_input"

# Imbalance semantics: one pin well below the rest
echo "400" >"$MOCK_HWMON/curr5_input"
assert_eq "55" "$(astral_get_balance_pct)" "55% ratio"
assert_eq "crit" "$(astral_balance_status)" "55% ratio should be critical"
echo "1000" >"$MOCK_HWMON/curr5_input"
assert_eq "64" "$(astral_get_balance_pct)" "64% ratio"
assert_eq "warn" "$(astral_balance_status)" "64% ratio should warn"
assert_eq "53.6" "$(astral_get_connector_power_w)" "connector power with raised pin 5"
echo "620" >"$MOCK_HWMON/curr5_input"

# No astral device -> unavailable (reset the cached discovery from above)
_ASTRAL_HWMON_DIR=""
export SYSFS_HWMON_DIR="$MOCK_SYS/empty"
mkdir -p "$SYSFS_HWMON_DIR"
assert_fails astral_available "no device in tree -> unavailable"
assert_eq "" "$(astral_get_total_current_ma)" "total on missing device"

export SYSFS_HWMON_DIR="$MOCK_SYS"
rm -rf "$MOCK_SYS"
