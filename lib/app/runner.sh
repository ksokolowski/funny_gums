#!/usr/bin/env bash
# runner.sh - Step execution with spinner animation
# Source this file for running commands with dashboard integration
# shellcheck disable=SC1091

# Prevent multiple sourcing
[[ -n "${_RUNNER_SH_LOADED:-}" ]] && return 0
_RUNNER_SH_LOADED=1

# Source dependencies
_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_RUNNER_DIR/../ui/widgets/spinner.sh"
source "$_RUNNER_DIR/dashboard.sh"
source "$_RUNNER_DIR/../core/sh/logging.sh"

# Current command PID for cleanup
RUNNER_CMD_PID=""

# Cleanup function for runner
runner_cleanup() {
    [[ -n "${RUNNER_CMD_PID:-}" ]] && kill "$RUNNER_CMD_PID" 2>/dev/null
}

# Run a command with spinner animation
# Usage: runner_exec index command [args...]
runner_exec() {
    local idx=$1
    shift

    # Skip disabled steps
    if [[ "${DASHBOARD_ENABLED[$idx]}" != "true" ]]; then
        dashboard_step_skip "$idx"
        return 0
    fi

    log_debug "Starting: ${DASHBOARD_STEPS[$idx]}"

    # Mark step as running
    dashboard_step_start "$idx"

    # Ensure cleanup on interrupt
    trap 'runner_cleanup' INT TERM

    # Run command in background
    "$@" >>"$LOG_FILE" 2>&1 &
    RUNNER_CMD_PID=$!

    # Animate spinner while command runs
    while kill -0 "$RUNNER_CMD_PID" 2>/dev/null; do
        sleep 0.1
        spinner_next
        dashboard_update_spinner
    done

    # Get exit code
    wait "$RUNNER_CMD_PID"
    local rc=$?
    RUNNER_CMD_PID=""

    # Restore default signal handlers
    trap - INT TERM

    # Update dashboard. Per-step status is communicated visually via the
    # dashboard's ✅/❌ markers and the post-run summary block. The log_*
    # calls below stay silent on stdout because dashboard_init sets
    # LOGGING_QUIET=true (see lib/core/sh/logging.sh) — failure lines still
    # land in LOG_FILE at ERROR level for post-mortem.
    if ((rc == 0)); then
        dashboard_step_done "$idx" true
        log_debug "Completed: ${DASHBOARD_STEPS[$idx]}"
    else
        dashboard_step_done "$idx" false
        log_error "Failed: ${DASHBOARD_STEPS[$idx]} (exit $rc)"
    fi

    return $rc
}

# Run multiple commands sequentially.
# Each argument is a single command string with its own arguments (e.g.
# "sudo apt update", "make test"); `bash -c` parses each into argv.
#
# SECURITY: `bash -c "$cmd"` is exactly as powerful as `eval` — anything in
# `$cmd` is interpreted by the shell. This is fine when `cmd` strings come
# from the script's own literal array (the standard usage in the bundled
# examples). It is NOT safe to pass user input here. If you need a structured
# command, call `runner_exec "$idx" cmd arg1 arg2 …` directly and bypass this
# convenience wrapper.
#
# Usage: runner_exec_all "cmd1" "cmd2" "cmd3"
runner_exec_all() {
    local idx=0
    for cmd in "$@"; do
        runner_exec "$idx" bash -c "$cmd"
        ((idx++))
    done
}
