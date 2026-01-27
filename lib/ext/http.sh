#!/usr/bin/env bash
# http.sh - HTTP client wrapper using curl + gum spin + jq
# shellcheck disable=SC2034,SC2155

[[ -n "${_EXT_HTTP_LOADED:-}" ]] && return 0
_EXT_HTTP_LOADED=1

# Source core dependencies
_EXT_HTTP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_EXT_HTTP_DIR/../core/spinner.sh"
source "$_EXT_HTTP_DIR/../core/logging.sh"

#######################################
# Fetch JSON data with spinner
# Usage: net_get_json "https://api.example.com/data"
# Returns:
#   JSON content on stdout if status 200
#   Returns 1 on failure
#######################################
net_get_json() {
    local url="$1"
    local response
    local http_code
    
    # Needs curl
    if ! command -v curl &>/dev/null; then
        echo "Error: curl is required for net_get_json" >&2
        return 1
    fi

    local tmp_body
    tmp_body=$(mktemp)
    
    # Run curl with spinner
    # We construct a command string that writes http_code to a status file
    # We use bash -c to handle the redirection and complex command
    local cmd="curl -s -w '%{http_code}' -o '$tmp_body' '$url' > '$tmp_body.status'"

    if ! ui_spin_type globe "Fetching data from ${url}..." bash -c "$cmd"; then
        rm -f "$tmp_body" "$tmp_body.status"
        log_error "Failed to execute fetch command"
        return 1
    fi
    
    http_code=$(cat "$tmp_body.status" 2>/dev/null)
    
    if [[ "$http_code" == "200" ]]; then
        if command -v jq &>/dev/null; then
            cat "$tmp_body" | jq .
        else
            cat "$tmp_body"
        fi
        rm -f "$tmp_body" "$tmp_body.status"
        return 0
    else
        log_error "HTTP Request failed. Code: $http_code"
        rm -f "$tmp_body" "$tmp_body.status"
        return 1
    fi
}
