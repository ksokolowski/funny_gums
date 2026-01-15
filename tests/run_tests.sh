#!/usr/bin/env bash
# run_tests.sh - Test runner for my_gums library
# Usage: ./tests/run_tests.sh [test_file...]
set -uo pipefail
# Note: We don't use -e because test assertions may "fail" intentionally

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

#######################################
# Run shellcheck on all scripts
#######################################
run_shellcheck() {
    test_file_start "shellcheck"
    ((TESTS_RUN++))

    if shellcheck --severity=error "$PROJECT_DIR/my_gums.sh" "$PROJECT_DIR/lib/"*.sh "$PROJECT_DIR/examples/"*.sh >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} All scripts pass shellcheck"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} Shellcheck found issues"
        shellcheck --severity=error "$PROJECT_DIR/my_gums.sh" "$PROJECT_DIR/lib/"*.sh "$PROJECT_DIR/examples/"*.sh 2>&1 | head -20
        ((TESTS_FAILED++))
        FAILED_TESTS+=("shellcheck: Scripts have linting errors")
    fi
}

#######################################
# Main
#######################################

echo "${CYAN}╔═══════════════════════════════════════╗${RESET}"
echo "${CYAN}║     my_gums Test Suite                ║${RESET}"
echo "${CYAN}╚═══════════════════════════════════════╝${RESET}"

# Run shellcheck first
run_shellcheck

# Find and run test files
if [[ $# -gt 0 ]]; then
    # Run specific test files
    for test_file in "$@"; do
        if [[ -f "$test_file" ]]; then
            source "$test_file"
        elif [[ -f "$SCRIPT_DIR/$test_file" ]]; then
            source "$SCRIPT_DIR/$test_file"
        else
            echo "${RED}Test file not found: $test_file${RESET}"
        fi
    done
else
    # Run all test files
    for test_file in "$SCRIPT_DIR"/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            source "$test_file"
        fi
    done
fi

# Print summary
print_summary
