#!/usr/bin/env bash
# gum_wrapper.sh - Centralized wrapper for gum commands
#
# Usage:
#   source gum_wrapper.sh
#   gum_exec input --placeholder "Type something..."

[[ -n "${_GUM_WRAPPER_LOADED:-}" ]] && return 0
_GUM_WRAPPER_LOADED=1

# Check availability
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed." >&2
    exit 1
fi

# Global defaults (can be overridden by environment)
: "${GUM_BORDER:=normal}"
: "${GUM_BORDER_FG:=212}"
: "${GUM_PADDING:=0 1}"
: "${GUM_MARGIN:=0}"

# Base execution wrapper
# Allows strict mode or error handling injection in future
gum_exec() {
    gum "$@"
}

# Styled output wrapper using global defaults
# Usage: gum_exec_style "Message"
gum_exec_style() {
    gum style \
        --border "$GUM_BORDER" \
        --border-foreground "$GUM_BORDER_FG" \
        --padding "$GUM_PADDING" \
        --margin "$GUM_MARGIN" \
        "$@"
}

# Consistent confirmation dialog
# Usage: gum_confirm "Message" && ...
gum_confirm() {
    local msg="$1"
    shift
    gum confirm "$msg" \
        --affirmative "Yes" \
        --negative "No" \
        "$@"
}
