#!/usr/bin/env bash
# runner.sh - Step execution with spinner animation
# Source this file for running commands with dashboard integration
# shellcheck disable=SC1091

# Prevent multiple sourcing
[[ -n "${_RUNNER_SH_LOADED:-}" ]] && return 0
_RUNNER_SH_LOADED=1

# Source dependencies
_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_RUNNER_DIR/../core/spinner.sh"
source "$_RUNNER_DIR/dashboard.sh"
source "$_RUNNER_DIR/../core/logging.sh"

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
    if ! ${DASHBOARD_ENABLED[$idx]}; then
        dashboard_step_skip "$idx"
        return 0
    fi

    log_debug "Starting: ${DASHBOARD_STEPS[$idx]}"

    # Mark step as running
    dashboard_step_start "$idx"

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

    # Update dashboard
    if ((rc == 0)); then
        dashboard_step_done "$idx" true
        log_debug "Completed: ${DASHBOARD_STEPS[$idx]}"
    else
        dashboard_step_done "$idx" false
        log_error "Failed: ${DASHBOARD_STEPS[$idx]}"
    fi

    return $rc
}

# Run multiple commands sequentially
# Usage: runner_exec_all "cmd1" "cmd2" "cmd3"
# Each command is run for its corresponding step index
runner_exec_all() {
    local idx=0
    for cmd in "$@"; do
        # Use bash -c to execute the command string safely without eval
        runner_exec "$idx" bash -c "$cmd"
        ((idx++))
    done
}
