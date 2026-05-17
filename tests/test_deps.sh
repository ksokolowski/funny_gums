#!/usr/bin/env bash
# test_deps.sh - Unit tests for deps.sh

test_file_start "deps.sh"

# Source the module
source "$PROJECT_DIR/lib/core/sh/deps.sh"

# Public function surface
assert_function_exists "dep_check"
assert_function_exists "dep_require_all"
assert_function_exists "dep_require_module"
assert_function_exists "dep_has_jq"
assert_function_exists "dep_suggest"

# dep_check: positive and negative
assert_success dep_check "bash"
assert_fails dep_check "definitely_not_a_real_command_xyz_$$"

# Standalone bootstrap: sourcing deps.sh on its own (no colors.sh pre-loaded)
# must still pull in colors/logging so that dep_require_all's coloured output
# and log_error fallback work. This is the documented "handle standalone usage"
# branch at the top of deps.sh.
standalone_red=$(bash -c "
    source '$PROJECT_DIR/lib/core/sh/deps.sh'
    printf '%s' \"\${RED:-MISSING}\"
")
assert_eq $'\e[31m' "$standalone_red" "standalone source of deps.sh bootstraps colors.sh (so RED is defined)"
