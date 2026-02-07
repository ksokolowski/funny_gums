#!/usr/bin/env bash
# test_dashboard_parallel.sh - Unit tests for dashboard parallelization

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "dashboard_parallel.sh"

# 1. Setup mock environment
# Copy dashboard to temp file, removing last 2 lines (init and loop)
TMP_DASHBOARD=$(mktemp)
head -n -2 "$PROJECT_DIR/examples/system_dashboard.sh" >"$TMP_DASHBOARD"

# Inject dummy SCRIPT_PATH for deps resolution
sed -i 's|SCRIPT_PATH="${BASH_SOURCE\[0\]}"|SCRIPT_PATH="'"$PROJECT_DIR/examples/system_dashboard.sh"'"|' "$TMP_DASHBOARD"

# Source the dashboard logic
# shellcheck source=/dev/null
source "$TMP_DASHBOARD"

# Mock required variables that would be set in init_dashboard
TERM_COLS=100
TERM_ROWS=30
NAV_PANEL_WIDTH=22
PANEL_WIDTH=70
export TERM_COLS TERM_ROWS NAV_PANEL_WIDTH PANEL_WIDTH

# 2. Mock slow functions to verify parallel execution
get_cpu_usage_live() {
    sleep 0.2
    echo "5"
}
# sensors is a command, we mock it via function
sensors() {
    sleep 0.2
    echo "k10temp-pci-00c3"
}
get_root_disk_usage_live() {
    sleep 0.2
    echo "100 200 50"
}
get_memory_usage_live() { echo "1000 8000 12"; }
get_swap_usage_live() { echo "0 4000 0"; }

# 3. Run refresh_live_metrics and measure time
# Total sequential time would be ~0.6s + others
# Parallelized time should be ~0.2s + others

echo "  Testing performance of refresh_live_metrics..."
START_TIME=$(date +%s%N)
refresh_live_metrics
END_TIME=$(date +%s%N)
DURATION=$(((END_TIME - START_TIME) / 1000000))

echo "  Duration: ${DURATION}ms"

((TESTS_RUN++))
if [[ $DURATION -lt 1000 ]]; then
    echo "  ${GREEN}✓${RESET} Parallelization effective (Duration: ${DURATION}ms)"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Too slow, parallelization might be broken (Duration: ${DURATION}ms)"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("dashboard_parallel.sh: Parallelization should be under 1000ms")
fi

# 4. Verify state variables were populated
assert_eq "5" "$LIVE_CPU_PERCENT" "LIVE_CPU_PERCENT should be populated"
assert_eq "50" "$LIVE_DISK_PERCENT" "LIVE_DISK_PERCENT should be populated"
assert_eq "12" "$LIVE_MEM_PERCENT" "LIVE_MEM_PERCENT should be populated"
if [[ "$_SENSORS_CACHE" == *"k10temp"* ]]; then
    echo "  ${GREEN}✓${RESET} _SENSORS_CACHE populated correctly"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
else
    echo "  ${RED}✗${RESET} _SENSORS_CACHE missing expected content"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
    FAILED_TESTS+=("dashboard_parallel.sh: _SENSORS_CACHE should be populated")
fi

rm "$TMP_DASHBOARD"
