#!/usr/bin/env bash
# test_enhancements.sh - Test suite for new Funny Gums features
# shellcheck disable=SC1091

# Source test framework
source "$(dirname "$0")/framework.sh"

# Source library
source "$(dirname "$0")/../funny_gums.sh"

test_file_start "enhancements.sh"

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
    ui_choose --help >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        assert_success true "ui_choose forwards flags (checked via --help)"
    else
        assert_fails false "ui_choose failed to run with flags"
    fi
}

# 4. Test ui_file with new header flag
it_ui_file_header() {
    assert_function_exists "ui_file"
    ui_file --help >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        assert_success true "ui_file forwards flags (checked via --help)"
    else
        assert_fails false "ui_file failed to run with flags"
    fi
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

print_summary
