#!/usr/bin/env bash
# gum_wrapper.sh - Centralized wrapper for gum commands
#
# Usage:
#   source gum_wrapper.sh
#   gum_exec input --placeholder "Type something..."

[[ -n "${_GUM_WRAPPER_LOADED:-}" ]] && return 0
_GUM_WRAPPER_LOADED=1

# Check availability
if ! command -v gum &>/dev/null; then
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

################################################################################
# VISUAL WIDTH-AWARE FUNCTIONS
# These functions compensate for VS16/ZWJ emoji width differences
# Requires: source lib/core/text.sh (for visual_width functions)
################################################################################

# Execute gum style with visual width compensation
# Automatically adjusts --width to account for VS16/ZWJ/wide characters
# Usage: gum_exec_style_visual "content" target_width [other_args...]
# Execute gum style with visual width compensation
# Automatically adjusts --width to account for VS16/ZWJ/wide characters
# Usage: gum_exec_style_visual "content" target_width [other_args...]
gum_exec_style_visual() {
    local content="$1"
    local target_width="$2"
    shift 2

    # Check if visual_width function is available
    if ! declare -f visual_width >/dev/null 2>&1; then
        # Fallback to regular style if text.sh not sourced
        gum_exec_style --width "$target_width" "$@" <<<"$content"
        return
    fi

    # Calculate adjusted width for gum (optimized, no subshell)
    local adjusted_width
    gum_adjusted_width_ref "$content" "$target_width" adjusted_width

    gum_exec_style --width "$adjusted_width" "$@" <<<"$content"
}

# Execute gum style with visual width compensation (multi-line)
# Takes content from stdin
# Usage: echo "content" | gum_exec_style_visual_stdin target_width [other_args...]
gum_exec_style_visual_stdin() {
    local target_width="$1"
    shift

    local content
    content=$(cat)

    gum_exec_style_visual "$content" "$target_width" "$@"
}

# Wrap text in a box with proper emoji alignment
# Usage: gum_box_visual "content" width [border_style]
gum_box_visual() {
    local content="$1"
    local width="$2"
    local border="${3:-$GUM_BORDER}"

    gum_exec_style_visual "$content" "$width" \
        --border "$border" \
        --border-foreground "$GUM_BORDER_FG" \
        --padding "$GUM_PADDING" \
        --margin "$GUM_MARGIN"
}

# Pre-pad multiline content for proper gum alignment
# Pads each line to target visual width, compensating for VS16/wide chars
# Usage: content=$(gum_prepad_content "$content" inner_width)
# Note: inner_width should be frame width minus border/padding chars
gum_prepad_content() {
    local content="$1"
    local inner_width="$2"

    # Check if visual_width function is available
    if ! declare -f visual_width >/dev/null 2>&1; then
        # Fallback: return content unchanged
        printf '%s' "$content"
        return
    fi

    local line
    local result=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Pad each line to inner_width using visual width calculation
        local padded
        padded=$(pad_visual "$line" "$inner_width" left)
        result+="${padded}"$'\n'
    done <<<"$content"

    # Remove trailing newline
    printf '%s' "${result%$'\n'}"
}
