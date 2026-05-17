#!/usr/bin/env bash
# test_strict_mode.sh - Catch unbound-variable and pipefail regressions
#
# Why: the NEON_RED_NUM abort in examples/openrgb_fix.sh slipped past every
# other test because shellcheck doesn't flag references to undefined names
# (only unused declarations) and `assert_function_exists` only checks the name,
# not what the body touches. This test loads the full library under
# `set -uo pipefail` and exercises a representative slice of the public API
# — both at source time (catches missing module-level globals) and at call
# time (catches missing globals referenced inside function bodies).
#
# Maintain by adding any newly-introduced public global or function here.

test_file_start "strict_mode.sh"

# The smoke script runs in its own subshell with strict mode on.
# Each `: "$VAR"` line aborts the subshell if VAR is unset.
read -r -d '' SMOKE_SCRIPT <<'SMOKE'
set -uo pipefail
source "$PROJECT_DIR/funny_gums.sh"

# Colors: basic + bright + styles + neon (both ANSI and _NUM siblings)
: "$BLACK" "$RED" "$GREEN" "$YELLOW" "$BLUE" "$MAGENTA" "$CYAN" "$WHITE"
: "$BRIGHT_BLACK" "$BRIGHT_RED" "$BRIGHT_GREEN" "$BRIGHT_YELLOW"
: "$BRIGHT_BLUE" "$BRIGHT_MAGENTA" "$BRIGHT_CYAN" "$BRIGHT_WHITE"
: "$BOLD" "$DIM" "$ITALIC" "$UNDERLINE" "$RESET"
: "$NEON_PINK" "$NEON_CYAN" "$NEON_PURPLE" "$NEON_YELLOW"
: "$NEON_GREEN" "$NEON_BLUE" "$NEON_ORANGE" "$NEON_RED"
: "$NEON_PINK_NUM" "$NEON_CYAN_NUM" "$NEON_PURPLE_NUM" "$NEON_YELLOW_NUM"
: "$NEON_GREEN_NUM" "$NEON_BLUE_NUM" "$NEON_ORANGE_NUM" "$NEON_RED_NUM"

# Semantic emoji constants the bundled examples use
: "$EMOJI_SUCCESS" "$EMOJI_FAILURE" "$EMOJI_WARNING" "$EMOJI_PENDING"
: "$EMOJI_SKIP" "$EMOJI_RUNNING" "$EMOJI_DONE" "$EMOJI_OK" "$EMOJI_ERROR"
: "$EMOJI_CPU" "$EMOJI_DISK" "$EMOJI_DISK_COL" "$EMOJI_DISK_HEAD"
: "$EMOJI_GPU" "$EMOJI_MEMORY" "$EMOJI_NETWORK" "$EMOJI_POWER" "$EMOJI_TEMP"
: "$EMOJI_SERVER" "$EMOJI_SPEAKER" "$EMOJI_PROCESS" "$EMOJI_SERVICE"
: "$EMOJI_PACKAGE" "$EMOJI_RGB" "$EMOJI_ALERT" "$EMOJI_SETUP"
: "$EMOJI_SAVE" "$EMOJI_LOCK" "$EMOJI_KEY"

# Module-level state globals
: "$DASHBOARD_TITLE" "$DASHBOARD_COMPLETED" "$DASHBOARD_RUNNING"
: "$DASHBOARD_HAS_FAILURE" "$DASHBOARD_PROGRESS_WIDTH" "$DASHBOARD_QUIET"
: "$DASHBOARD_SPINNER" "$DASHBOARD_BORDER_COLOR" "$DASHBOARD_PROGRESS_COLOR"
: "$DASHBOARD_LINES"
: "$SPINNER_IDX"
: "$LOG_FILE" "$VERBOSE"
: "$SUDO_KEEPALIVE_PID" "$SUDO_FRAME_WIDTH"
: "$RUNNER_CMD_PID"
: "$TERMINAL_CAPABILITY" "$TERMINAL_MODE"

# Pure / state-only function calls — these trip on unset locals or refs
# inside function bodies that the source-time globals above don't cover.
colorize "$RED" "smoke" >/dev/null
visual_width "Hello World" >/dev/null
strip_ansi $'\e[31mred\e[0m' >/dev/null
strlen_no_ansi "test" >/dev/null
format_bytes 1024 >/dev/null
format_kb 1024 >/dev/null
spinner_set DOTS
spinner_next
spinner_frame >/dev/null
spinner_reset
detect_terminal_capability
get_terminal_capability >/dev/null

# Gauge / status (depend on threshold + colour resolution)
ui_gauge 50 100 >/dev/null
ui_gauge_colored 75 100 >/dev/null
ui_temp_gauge 65 >/dev/null
ui_vbar 50 >/dev/null
ui_status OK >/dev/null
ui_status CRIT >/dev/null
ui_minibar 50 >/dev/null
ui_minibar_colored 50 >/dev/null

# Dashboard state machine — exercises every step transition with QUIET=true
# so no terminal output is produced.
DASHBOARD_QUIET=true
dashboard_init "smoke"
dashboard_add_step "alpha"
dashboard_add_step "beta"
dashboard_enable_step 0 false
dashboard_enabled_count >/dev/null
dashboard_step_start 1
dashboard_step_done 1 true
dashboard_has_failure || true

# UI box family — render to /dev/null but exercises the full gum_exec_style
# arg expansion path. These are non-interactive (no stdin required).
ui_box "smoke" >/dev/null 2>&1
ui_error "smoke" >/dev/null 2>&1
ui_success "smoke" >/dev/null 2>&1
ui_warn "smoke" >/dev/null 2>&1
ui_info "smoke" >/dev/null 2>&1

echo OK
SMOKE

# Run in a clean subshell. PROJECT_DIR is exported so funny_gums.sh resolves.
export PROJECT_DIR
smoke_output=$(bash -c "$SMOKE_SCRIPT" 2>&1)
smoke_rc=$?

if ((smoke_rc != 0)) || [[ "${smoke_output##*$'\n'}" != "OK" ]]; then
    echo "  ${RED}Strict-mode smoke failed (rc=$smoke_rc). Last 10 lines:${RESET}"
    printf '%s\n' "$smoke_output" | tail -10 | sed 's/^/    /'
fi

assert_eq 0 "$smoke_rc" "library loads + public API exercises cleanly under set -uo pipefail"
assert_eq "OK" "${smoke_output##*$'\n'}" "smoke script reached its final 'OK' (no early abort)"
