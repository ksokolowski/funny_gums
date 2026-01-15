#!/usr/bin/env bash
# sudo.sh - Sudo authentication helpers
# Source this file for sudo credential management

# Prevent multiple sourcing
[[ -n "${_SUDO_SH_LOADED:-}" ]] && return 0
_SUDO_SH_LOADED=1

# PID of the sudo keepalive background process
SUDO_KEEPALIVE_PID=""

# Authenticate sudo and cache credentials
# Returns 0 on success, 1 on failure
sudo_auth() {
    if ! sudo -v 2>/dev/null; then
        echo "This script requires sudo privileges."
        sudo -v || return 1
    fi
    return 0
}

# Start background process to keep sudo credentials alive
# Usage: sudo_keepalive_start [interval_seconds]
sudo_keepalive_start() {
    local interval="${1:-50}"
    (while true; do sudo -n true; sleep "$interval"; done) &
    SUDO_KEEPALIVE_PID=$!
}

# Stop the sudo keepalive background process
sudo_keepalive_stop() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
        SUDO_KEEPALIVE_PID=""
    fi
}

# Full sudo setup: authenticate and start keepalive
# Usage: sudo_setup [keepalive_interval]
sudo_setup() {
    sudo_auth || return 1
    sudo_keepalive_start "${1:-50}"
    return 0
}

# Cleanup function to be called on script exit
# Usage: trap sudo_cleanup EXIT
sudo_cleanup() {
    sudo_keepalive_stop
}
