#!/usr/bin/env bash
# logging.sh - Logging functions using gum
# Source this file for structured logging with gum

# Prevent multiple sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
_LOGGING_SH_LOADED=1

# Default log file (can be overridden before sourcing)
: "${LOG_FILE:=/tmp/gum_script.log}"
: "${VERBOSE:=false}"

# Initialize log file
log_init() {
    local file="${1:-$LOG_FILE}"
    LOG_FILE="$file"
    : >"$LOG_FILE"
}

# Log info level
log_info() {
    gum log --level info "$@" | tee -a "$LOG_FILE"
}

# Log warning level
log_warn() {
    gum log --level warn "$@" | tee -a "$LOG_FILE"
}

# Log error level
log_error() {
    gum log --level error "$@" | tee -a "$LOG_FILE"
}

# Log debug level (only if VERBOSE=true)
log_debug() {
    $VERBOSE && gum log --level debug "$@" | tee -a "$LOG_FILE"
}

# Log with timestamp
log_time() {
    gum log --time rfc3339 --level info "$@" | tee -a "$LOG_FILE"
}

# Structured log with key-value pairs
# Usage: log_structured info "Processing file" filename "test.txt" size 1024
# Usage: log_structured error "Failed" error_code 500 endpoint "/api/users"
log_structured() {
    local level="$1"
    local msg="$2"
    shift 2
    gum log --structured --level "$level" "$msg" "$@" | tee -a "$LOG_FILE"
}

# Log with custom prefix
# Usage: log_prefix "[MyApp]" info "Starting..."
log_prefix() {
    local prefix="$1"
    local level="$2"
    shift 2
    gum log --prefix "$prefix" --level "$level" "$@" | tee -a "$LOG_FILE"
}

# Log fatal (error level with "FATAL" styling - exits script)
# Usage: log_fatal "Critical error occurred"
log_fatal() {
    gum log --level fatal "$@" | tee -a "$LOG_FILE"
    exit 1
}

# Show log file in pager
log_show() {
    gum pager < "$LOG_FILE"
}
