#!/usr/bin/env bash
# deps.sh - Dependency management and verification
# This module provides functions to check for required external tools
# and enforce strict dependency requirements.

# Prevent multiple sourcing
[[ -n "${_DEPS_SH_LOADED:-}" ]] && return 0
_DEPS_SH_LOADED=1

# Source colors/logging if available (but handle standalone usage)
_DEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${_COLORS_SH_LOADED:-}" ]] && [[ -f "$_DEPS_DIR/colors.sh" ]]; then
    source "$_DEPS_DIR/colors.sh"
    source "$_DEPS_DIR/logging.sh"
fi

#######################################
# Check if a command exists
# Arguments:
#   $1 - Command to check
# Returns:
#   0 if exists, 1 if missing
#######################################
dep_check() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

#######################################
# Require a list of dependencies (strict)
# Fails with a summary if any are missing.
# Arguments:
#   $@ - List of commands to require
# Returns:
#   0 if all present, exits 1 if any missing
#######################################
dep_require_all() {
    local missing=()
    local cmd

    for cmd in "$@"; do
        if ! dep_check "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        # Try to use UI/colors if available
        if [[ -n "${RED:-}" ]]; then
            echo "${RED}Wrapper Error: Missing required dependencies:${RESET}" >&2
        else
            echo "Wrapper Error: Missing required dependencies:" >&2
        fi

        for cmd in "${missing[@]}"; do
             echo "  - $cmd" >&2
        done
        
        # If logging module is loaded, try to log it
        if declare -f log_error >/dev/null; then
             log_error "Missing dependencies: ${missing[*]}"
        fi

        exit 1
    fi
}

#######################################
# Require a specific module dependency
# Returns failure instead of exiting.
# Arguments:
#   $1 - Command to require
#   $2 - Optional friendly name/reason
# Returns:
#   0 if present, 1 if missing (and logs error)
#######################################
dep_require_module() {
    local cmd="$1"
    local reason="${2:-Required for this feature}"

    if ! dep_check "$cmd"; then
        if declare -f log_error >/dev/null; then
            log_error "Missing dependency '$cmd': $reason"
        else
            echo "Error: Missing dependency '$cmd': $reason" >&2
        fi
        return 1
    fi
}

#######################################
# Check if jq is available (helper)
# Returns:
#   0 if yes, 1 if no
#######################################
dep_has_jq() {
    dep_check "jq"
}

#######################################
# Suggest an optional dependency
# Logs a warning if missing, but returns 0.
# Arguments:
#   $1 - Command to check
#   $2 - Reason/Feature description
#######################################
dep_suggest() {
    local cmd="$1"
    local reason="$2"
    
    if ! dep_check "$cmd"; then
        # Check if we can use colors (might be loaded)
        local yellow=""
        local reset=""
        if [[ -n "${YELLOW:-}" ]]; then
             yellow="$YELLOW"
             reset="$RESET"
        fi
        echo "${yellow}Suggestion: Install '$cmd' for $reason${reset}" >&2
        return 1 # Return 1 so caller knows it's missing (boolean check)
    fi
    return 0
}
