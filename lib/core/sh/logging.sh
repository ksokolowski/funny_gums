#!/usr/bin/env bash
# logging.sh - Logging functions using gum
# Source this file for structured logging with gum

# Prevent multiple sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
_LOGGING_SH_LOADED=1

_LOGGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_LOGGING_DIR/gum_wrapper.sh"

# Default log file (can be overridden before sourcing)
: "${LOG_FILE:=/tmp/gum_script.log}"
: "${VERBOSE:=false}"

# LOGGING_QUIET contract:
#   When a TUI component owns the terminal (a dashboard mid-redraw, a custom
#   full-screen UI), set LOGGING_QUIET=true and the log_* family writes only
#   to LOG_FILE — no `tee` to stdout, so the cursor accounting in dashboard_draw
#   (and similar) stays consistent. dashboard_init sets this for you;
#   dashboard_cleanup clears it. Callers that build their own TUI on the
#   library should toggle it manually.
: "${LOGGING_QUIET:=false}"

# Initialize log file
log_init() {
    local file="${1:-$LOG_FILE}"
    LOG_FILE="$file"
    : >"$LOG_FILE"
}

# Internal: emit one gum log line. Honours LOGGING_QUIET — when true the
# message goes to LOG_FILE only; when false it `tee`s to stdout as well.
# All public log_* functions route through here so the rule applies uniformly.
_log_emit() {
    if [[ "${LOGGING_QUIET:-false}" == "true" ]]; then
        gum_exec log "$@" >>"$LOG_FILE" 2>&1
        return $?
    fi
    gum_exec log "$@" 2>&1 | tee -a "$LOG_FILE"
    return "${PIPESTATUS[0]}"
}

# Log info level
log_info() {
    _log_emit --level info "$@"
}

# Log info to file only (no console output regardless of LOGGING_QUIET)
log_silent() {
    gum_exec log --level info "$@" >>"$LOG_FILE" 2>&1
}

# Log warning level
log_warn() {
    _log_emit --level warn "$@"
}

# Log error level
log_error() {
    _log_emit --level error "$@"
}

# Log debug level (only if VERBOSE=true)
log_debug() {
    [[ "$VERBOSE" == "true" ]] || return 0
    _log_emit --level debug "$@"
}

# Log with timestamp
log_time() {
    _log_emit --time rfc3339 --level info "$@"
}

# Structured log with key-value pairs
# Usage: log_structured info "Processing file" filename "test.txt" size 1024
# Usage: log_structured error "Failed" error_code 500 endpoint "/api/users"
log_structured() {
    local level="$1"
    local msg="$2"
    shift 2
    _log_emit --structured --level "$level" "$msg" "$@"
}

# Log with custom prefix
# Usage: log_prefix "[MyApp]" info "Starting..."
log_prefix() {
    local prefix="$1"
    local level="$2"
    shift 2
    _log_emit --prefix "$prefix" --level "$level" "$@"
}

# Log fatal (error level with "FATAL" styling - exits script).
# Honours LOGGING_QUIET like the others; if a TUI is mid-redraw and you want
# the fatal message visible, emit a `ui_error` yourself before exiting.
# Usage: log_fatal "Critical error occurred"
log_fatal() {
    _log_emit --level fatal "$@"
    exit 1
}

# Show log file in pager
log_show() {
    gum_exec pager <"$LOG_FILE"
}
