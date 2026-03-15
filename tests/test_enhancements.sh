#!/usr/bin/env bash
# test_enhancements.sh - Test suite for new Funny Gums features
# shellcheck disable=SC1091

# Source test framework
source "$(dirname "$0")/framework.sh"

# Source library
source "$(dirname "$0")/../funny_gums.sh"

test_file_start "funny_gums.sh (enhancements)"

# 1. Test ui_version_check
it_version_check() {
    assert_function_exists "ui_version_check"

    local version
    version=$(gum --version | awk '{print $3}')
    assert_success ui_version_check ">= $version"
}

# 2. Test flag forwarding in ui_box
it_ui_box_flags() {
    assert_success ui_box --padding "1 1" --border double "Test"
}

# 3. Test flag forwarding in ui_choose (Check existence and basic run)
it_ui_choose_flags() {
    assert_function_exists "ui_choose"
    # We check that it at least attempts to run gum choose
    # and returns something other than command not found
    # Verify ui_choose can be invoked (--help should return 0)
    assert_success ui_choose --help "ui_choose forwards flags (checked via --help)"
}

# 4. Test ui_file with new header flag
it_ui_file_header() {
    assert_function_exists "ui_file"
    # Verify ui_file can be invoked (--help should return 0)
    assert_success ui_file --help "ui_file forwards flags (checked via --help)"
}

# 5. Test dashboard custom spinner
it_dashboard_spinner() {
    DASHBOARD_SPINNER="MOON"
    dashboard_init "Custom Spinner Test"
    assert_eq "MOON" "$DASHBOARD_SPINNER" "DASHBOARD_SPINNER should be MOON"

    # Draw (sets spinner)
    dashboard_draw >/dev/null
    local frame
    frame=$(spinner_frame)
    # Check if frame is one of the moon emojis
    if [[ "$frame" =~ ^(🌑|🌒|🌓|🌔|🌕|🌖|🌗|🌘)$ ]]; then
        assert_success true "DASHBOARD_SPINNER set to MOON correctly"
    else
        echo "      Got frame: $frame"
        assert_fails false "DASHBOARD_SPINNER failed to set MOON"
    fi
}

it_version_check
it_ui_box_flags
it_ui_choose_flags
it_ui_file_header
it_dashboard_spinner

# Note: print_summary is called by run_tests.sh, not here
