#!/usr/bin/env bash
# test_emojis.sh - Unit tests for emojis.sh
# Verifies emoji constants are defined and non-empty

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "emojis.sh"

# Source the module
source "$PROJECT_DIR/lib/core/text/emojis.sh"

# Test that core emoji functions exist
assert_function_exists "detect_terminal_capability"
assert_function_exists "is_modern_terminal"

# Test that essential emoji constants are defined and non-empty
assert_not_empty "$EMOJI_SUCCESS" "EMOJI_SUCCESS should be defined"
assert_not_empty "$EMOJI_FAILURE" "EMOJI_FAILURE should be defined"
assert_not_empty "$EMOJI_WARNING" "EMOJI_WARNING should be defined"
assert_not_empty "$EMOJI_ERROR" "EMOJI_ERROR should be defined"
assert_not_empty "$EMOJI_OK" "EMOJI_OK should be defined"
assert_not_empty "$EMOJI_PENDING" "EMOJI_PENDING should be defined"
assert_not_empty "$EMOJI_RUNNING" "EMOJI_RUNNING should be defined"
assert_not_empty "$EMOJI_DONE" "EMOJI_DONE should be defined"
assert_not_empty "$EMOJI_SKIP" "EMOJI_SKIP should be defined"

# Test hardware emoji constants
assert_not_empty "$EMOJI_CPU" "EMOJI_CPU should be defined"
assert_not_empty "$EMOJI_MEMORY" "EMOJI_MEMORY should be defined"
assert_not_empty "$EMOJI_DISK" "EMOJI_DISK should be defined"
assert_not_empty "$EMOJI_GPU" "EMOJI_GPU should be defined"
assert_not_empty "$EMOJI_TEMP" "EMOJI_TEMP should be defined"

# Test colored circle constants
assert_not_empty "$EMOJI_RED" "EMOJI_RED should be defined"
assert_not_empty "$EMOJI_GREEN" "EMOJI_GREEN should be defined"
assert_not_empty "$EMOJI_YELLOW" "EMOJI_YELLOW should be defined"
assert_not_empty "$EMOJI_BLUE" "EMOJI_BLUE should be defined"
