#!/usr/bin/env bash
# test_gauge_float.sh - Verify gauge functions handle floats

source lib/core/colors.sh
source lib/ui/gauge.sh

echo "━━━ Testing: Float Handling ━━━"

# Test _ui_threshold_color with float
echo "Testing _ui_threshold_color with 48.6..."
color=$(_ui_threshold_color "48.6" "70" "90")
if [[ "$color" == "$NEON_GREEN" ]]; then
    echo -e "${GREEN}  ✓ Handled 48.6 correctly (Green)${RESET}"
else
    echo -e "${RED}  ✗ Failed to handle 48.6 (Got: $color)${RESET}"
    exit 1
fi

# Test ui_gauge with float
echo "Testing ui_gauge with 48.6..."
output=$(ui_gauge "48.6" "100" "20" "Test")
if [[ "$output" =~ "48%" ]]; then
    echo -e "${GREEN}  ✓ ui_gauge handled 48.6 correctly${RESET}"
else
    echo -e "${RED}  ✗ ui_gauge failed (Output: $output)${RESET}"
    exit 1
fi

echo "Testing ui_gauge_colored with 48.6..."
output=$(ui_gauge_colored "48.6" "100" "20" "Test" "70" "90")
if [[ "$output" =~ "48%" ]]; then
     echo -e "${GREEN}  ✓ ui_gauge_colored handled 48.6 correctly${RESET}"
else
     echo -e "${RED}  ✗ ui_gauge_colored failed${RESET}"
     exit 1
fi

exit 0
