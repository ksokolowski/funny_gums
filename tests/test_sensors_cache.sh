#!/usr/bin/env bash
# test_sensors_cache.sh - Unit tests for sensor caching logic

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "sensors.sh (caching)"

# Mock sensors command and a counter to track calls
CALL_COUNT_FILE=$(mktemp)
echo 0 >"$CALL_COUNT_FILE"
get_call_count() { cat "$CALL_COUNT_FILE"; }
increment_call_count() {
    local count
    count=$(get_call_count)
    echo $((count + 1)) >"$CALL_COUNT_FILE"
}

unset -f sensors sensors_available
sensors() {
    increment_call_count
    cat <<EOF
k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +46.6°C
EOF
}

# Mock check
sensors_available() { return 0; }

# Source library under test
source "$PROJECT_DIR/lib/mod/hw/sensors.sh"

# Reset state to ensure clean test environment
_SENSORS_CACHE=""
echo 0 >"$CALL_COUNT_FILE"

# 1. Test Initial State (cache empty)
assert_eq "" "$_SENSORS_CACHE" "Cache should be empty initially"

# 2. Test sensors_update_cache
sensors_update_cache
if [[ -n "$_SENSORS_CACHE" ]]; then
    echo "  ${GREEN}✓${RESET} Sensors cache populated after update"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Sensors cache empty after update"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("sensors_cache.sh: Cache should be populated")
fi
((TESTS_RUN++))
assert_eq 1 "$(get_call_count)" "Sensors command should have been called once"

# 3. Test that functions use cache (no new sensors calls)
temp=$(sensors_get_cpu_temp_smart)
assert_eq "46.6" "$temp" "Result should be correct using cache"
assert_eq 1 "$(get_call_count)" "Sensors command should NOT have been called again"

# 4. Test fallback to direct call if cache is cleared
_SENSORS_CACHE=""
temp=$(sensors_get_cpu_temp_smart)
assert_eq "46.6" "$temp" "Result should still be correct after cache clear"
assert_eq 2 "$(get_call_count)" "Sensors command should have been called again after cache clear"

# 5. Test sensors_update_cache updates cache
sensors_update_cache
assert_eq 3 "$(get_call_count)" "Sensors update cache should increment call count"

rm "$CALL_COUNT_FILE"
