#!/usr/bin/env bash
# test_gauge_float.sh - Verify gauge functions handle floats

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "gauge_float.sh"

# Source modules
source "$PROJECT_DIR/lib/core/term/colors.sh"
source "$PROJECT_DIR/lib/ui/widgets/gauge.sh"

# Test _ui_threshold_color with float
color=$(_ui_threshold_color "48.6" "70" "90")
assert_eq "$NEON_GREEN" "$color" "_ui_threshold_color should handle float 48.6"

# Test ui_gauge with float
output=$(ui_gauge "48.6" "100" "20" "Test")
((TESTS_RUN++))
if [[ "$output" =~ "48%" ]]; then
    echo "  ${GREEN}✓${RESET} ui_gauge handled 48.6 correctly"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} ui_gauge failed (Output: $output)"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("gauge_float.sh: ui_gauge should handle float 48.6")
fi

# Test ui_gauge_colored with float
output=$(ui_gauge_colored "48.6" "100" "20" "Test" "70" "90")
((TESTS_RUN++))
if [[ "$output" =~ "48%" ]]; then
    echo "  ${GREEN}✓${RESET} ui_gauge_colored handled 48.6 correctly"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} ui_gauge_colored failed"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("gauge_float.sh: ui_gauge_colored should handle float 48.6")
fi
