#!/usr/bin/env bash
# framework.sh - Test assertion framework for my_gums
# This file is sourced by run_tests.sh and provides assertion functions
# shellcheck disable=SC2034

# Prevent multiple sourcing
[[ -n "${_TEST_FRAMEWORK_LOADED:-}" ]] && return 0
_TEST_FRAMEWORK_LOADED=1

# Colors for output
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
CYAN=$'\e[36m'
RESET=$'\e[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST_FILE=""

# Test result tracking
declare -a FAILED_TESTS=()

#######################################
# Test framework functions
#######################################

# Start a test file
test_file_start() {
    CURRENT_TEST_FILE="$1"
    echo ""
    echo "${CYAN}━━━ Testing: $1 ━━━${RESET}"
}

# Assert that two values are equal
# Usage: assert_eq "expected" "actual" "message"
assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    ((TESTS_RUN++))

    if [[ "$expected" == "$actual" ]]; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a string contains another string
# Usage: assert_contains "substring" "string" "message"
assert_contains() {
    local expected="$1"
    local actual="$2"
    local message="${3:-String should contain '$expected'}"
    ((TESTS_RUN++))

    if [[ "$actual" == *"$expected"* ]]; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        echo "    String does not contain: '$expected'"
        echo "    Actual: '$actual'"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a value is not empty
# Usage: assert_not_empty "value" "message"
assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    ((TESTS_RUN++))

    if [[ -n "$value" ]]; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        echo "    Value was empty"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a command succeeds
# Usage: assert_success command [args...]
assert_success() {
    local message="Command should succeed: $1"
    ((TESTS_RUN++))

    if "$@" >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a command fails
# Usage: assert_fails command [args...]
assert_fails() {
    local message="Command should fail: $1"
    ((TESTS_RUN++))

    if ! "$@" >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a function exists
# Usage: assert_function_exists "function_name"
assert_function_exists() {
    local func_name="$1"
    local message="Function '$func_name' should exist"
    ((TESTS_RUN++))

    if declare -f "$func_name" >/dev/null 2>&1; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Assert that a variable is defined
# Usage: assert_var_defined "VAR_NAME"
assert_var_defined() {
    local var_name="$1"
    local message="Variable '$var_name' should be defined"
    ((TESTS_RUN++))

    if [[ -v "$var_name" ]]; then
        echo "  ${GREEN}✓${RESET} $message"
        ((TESTS_PASSED++))
    else
        echo "  ${RED}✗${RESET} $message"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$CURRENT_TEST_FILE: $message")
    fi
}

# Print test summary
print_summary() {
    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${CYAN}Test Summary${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "  Total:  $TESTS_RUN"
    echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
    echo "  ${RED}Failed: $TESTS_FAILED${RESET}"

    if ((TESTS_FAILED > 0)); then
        echo ""
        echo "${RED}Failed tests:${RESET}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ${RED}✗${RESET} $test"
        done
        echo ""
        return 1
    else
        echo ""
        echo "${GREEN}All tests passed!${RESET}"
        return 0
    fi
}
