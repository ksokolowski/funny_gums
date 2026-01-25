#!/usr/bin/env bash
# base.sh - Basic styled output functions using gum
# shellcheck disable=SC2034

_UI_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_BASE_DIR/../core/gum_wrapper.sh"

[[ -n "${_UI_BASE_LOADED:-}" ]] && return 0
_UI_BASE_LOADED=1

# Show styled box with title and content
# Usage: ui_box "Title" "line1" "line2" ...
ui_box() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground 6 --padding "1 2" "$@"
}

# Show styled box with double border
# Usage: ui_box_double "Title" "line1" "line2" ...
ui_box_double() {
    gum_exec_style --no-strip-ansi --border double --border-foreground 6 --padding "1 2" "$@"
}

# Show success message
# Usage: ui_success "Message"
ui_success() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground 2 --padding "1 4" --align center "$@"
}

# Show error message
# Usage: ui_error "Message"
ui_error() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground 1 --padding "1 4" --align center "$@"
}

# Show warning message
# Usage: ui_warn "Message"
ui_warn() {
    gum_exec_style --no-strip-ansi --border rounded --border-foreground 3 --padding "1 4" --align center "$@"
}

# Show info message (no border)
# Usage: ui_info "Message"
ui_info() {
    gum_exec_style --foreground 6 "$@"
}
