#!/usr/bin/env bash
# base.sh - Basic styled output functions using gum
# shellcheck disable=SC2034

[[ -n "${_UI_BASE_LOADED:-}" ]] && return 0
_UI_BASE_LOADED=1

_UI_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_BASE_DIR/../../core/sh/gum_wrapper.sh"
source "$_UI_BASE_DIR/../../core/term/colors.sh"

# Show styled box with title and content
# Usage: ui_box "Title" "line1" "line2" ...
ui_box() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground "$ANSI_CYAN_NUM" --padding "1 2" "$@"
}

# Show styled box with double border
# Usage: ui_box_double "Title" "line1" "line2" ...
ui_box_double() {
    gum_exec_style --no-strip-ansi --border double --border-foreground "$ANSI_CYAN_NUM" --padding "1 2" "$@"
}

# Show success message
# Usage: ui_success "Message"
ui_success() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground "$ANSI_GREEN_NUM" --padding "1 4" --align center "$@"
}

# Show error message
# Usage: ui_error "Message"
ui_error() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground "$ANSI_RED_NUM" --padding "1 4" --align center "$@"
}

# Show warning message
# Usage: ui_warn "Message"
ui_warn() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground "$ANSI_YELLOW_NUM" --padding "1 4" --align center "$@"
}

# Show info message (no border)
# Usage: ui_info "Message"
ui_info() {
    gum_exec_style --no-strip-ansi --foreground "$ANSI_CYAN_NUM" "$@"
}

# Show generic styled text
# Usage: ui_text "Message"
ui_text() {
    gum_exec_style --no-strip-ansi "$@"
}
