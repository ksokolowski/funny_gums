#!/usr/bin/env bash
# ui.sh - UI helper functions using gum
# Source this file for common UI patterns

# Prevent multiple sourcing
[[ -n "${_UI_SH_LOADED:-}" ]] && return 0
_UI_SH_LOADED=1

# Show styled box with title and content
# Usage: ui_box "Title" "line1" "line2" ...
ui_box() {
    gum style --border rounded --border-foreground 6 --padding "1 2" "$@"
}

# Show styled box with double border
# Usage: ui_box_double "Title" "line1" "line2" ...
ui_box_double() {
    gum style --border double --border-foreground 6 --padding "1 2" "$@"
}

# Show success message
# Usage: ui_success "Message"
ui_success() {
    gum style --border rounded --border-foreground 2 --padding "1 4" --align center "$@"
}

# Show error message
# Usage: ui_error "Message"
ui_error() {
    gum style --border rounded --border-foreground 1 --padding "1 4" --align center "$@"
}

# Show warning message
# Usage: ui_warn "Message"
ui_warn() {
    gum style --border rounded --border-foreground 3 --padding "1 4" --align center "$@"
}

# Show info message (no border)
# Usage: ui_info "Message"
ui_info() {
    gum style --foreground 6 "$@"
}

# Confirm dialog
# Usage: if ui_confirm "Are you sure?"; then ... fi
# Usage: ui_confirm "Continue?" --default=false
ui_confirm() {
    gum confirm "$@"
}

# Single choice selection
# Usage: result=$(ui_choose "Option1" "Option2" "Option3")
ui_choose() {
    printf '%s\n' "$@" | gum choose
}

# Multi-choice selection
# Usage: result=$(ui_choose_multi "Option1" "Option2" "Option3")
ui_choose_multi() {
    printf '%s\n' "$@" | gum choose --no-limit
}

# Choice with header
# Usage: result=$(ui_choose_with_header "Select an option:" "Opt1" "Opt2")
ui_choose_with_header() {
    local header="$1"
    shift
    printf '%s\n' "$@" | gum choose --header "$header"
}

# Text input
# Usage: result=$(ui_input "Enter your name")
ui_input() {
    local placeholder="${1:-Enter text...}"
    gum input --placeholder "$placeholder"
}

# Password input
# Usage: result=$(ui_password "Enter password")
ui_password() {
    local placeholder="${1:-Enter password...}"
    gum input --password --placeholder "$placeholder"
}

# Multi-line text input
# Usage: result=$(ui_write "Enter description")
ui_write() {
    local placeholder="${1:-Enter text...}"
    gum write --placeholder "$placeholder"
}

# Filter/search from list
# Usage: result=$(echo -e "item1\nitem2\nitem3" | ui_filter)
ui_filter() {
    gum filter "$@"
}

# File picker
# Usage: result=$(ui_file "/path/to/dir")
ui_file() {
    gum file "${1:-.}"
}

# Spinner while command runs
# Usage: ui_spin "Loading..." command args...
ui_spin() {
    local title="$1"
    shift
    gum spin --title "$title" -- "$@"
}

# Join text horizontally
# Usage: ui_join_h "text1" "text2"
ui_join_h() {
    local result=""
    for text in "$@"; do
        if [[ -z "$result" ]]; then
            result="$text"
        else
            result=$(gum join --horizontal "$result" "$text")
        fi
    done
    echo "$result"
}

# Join text vertically
# Usage: ui_join_v "text1" "text2"
ui_join_v() {
    local result=""
    for text in "$@"; do
        if [[ -z "$result" ]]; then
            result="$text"
        else
            result=$(gum join --vertical "$result" "$text")
        fi
    done
    echo "$result"
}
