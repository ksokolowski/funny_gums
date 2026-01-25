#!/usr/bin/env bash
# sudo.sh - Sudo authentication helpers
# Source this file for sudo credential management

# Prevent multiple sourcing
[[ -n "${_SUDO_SH_LOADED:-}" ]] && return 0
_SUDO_SH_LOADED=1

# Source gum wrapper if available
_SUDO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=gum_wrapper.sh
[[ -f "$_SUDO_DIR/gum_wrapper.sh" ]] && source "$_SUDO_DIR/gum_wrapper.sh"

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

# Width for styled sudo prompt (can be set before calling)
SUDO_FRAME_WIDTH=""

# Styled sudo authentication using gum
# Shows a framed password prompt with gum input
# Set SUDO_FRAME_WIDTH before calling to control width
# Returns 0 on success, 1 on failure
sudo_auth_styled() {
    # Check if already authenticated
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    # Check if gum is available
    if ! command -v gum &>/dev/null; then
        sudo_auth
        return $?
    fi

    local max_attempts=3
    local attempt=1
    local width_arg=""
    [[ -n "$SUDO_FRAME_WIDTH" ]] && width_arg="--width $SUDO_FRAME_WIDTH"

    while ((attempt <= max_attempts)); do
        # Show styled prompt
        # shellcheck disable=SC2086
        gum style --border rounded --border-foreground 214 --padding "0 2" $width_arg \
            "🔐 Sudo authentication required"
        echo ""

        # Get password with gum (input width slightly less than frame)
        local input_width=40
        [[ -n "$SUDO_FRAME_WIDTH" ]] && input_width=$((SUDO_FRAME_WIDTH - 10))
        local password
        password=$(gum input --password --placeholder "Enter sudo password..." \
            --prompt "🔑 " --prompt.foreground 214 \
            --width "$input_width")

        # User cancelled (empty input from Ctrl+C)
        if [[ -z "$password" ]]; then
            echo ""
            gum style --foreground 196 "Authentication cancelled."
            return 1
        fi

        # Try to authenticate
        if echo "$password" | sudo -S true 2>/dev/null; then
            return 0
        else
            ((attempt++))
            if ((attempt <= max_attempts)); then
                gum style --foreground 196 "✗ Incorrect password. Attempt $attempt of $max_attempts"
            fi
        fi
    done

    echo ""
    gum style --foreground 196 "✗ Authentication failed after $max_attempts attempts"
    return 1
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

# Styled sudo setup: authenticate with gum UI and start keepalive
# Usage: sudo_setup_styled [keepalive_interval]
sudo_setup_styled() {
    sudo_auth_styled || return 1
    sudo_keepalive_start "${1:-50}"
    return 0
}

# Cleanup function to be called on script exit
# Usage: trap sudo_cleanup EXIT
sudo_cleanup() {
    sudo_keepalive_stop
}
