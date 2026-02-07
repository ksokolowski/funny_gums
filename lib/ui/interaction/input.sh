#!/usr/bin/env bash
# input.sh - Interactive input and dialog functions using gum
# shellcheck disable=SC2034

_INPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_INPUT_DIR/../../core/sh/gum_wrapper.sh"

[[ -n "${_UI_INPUT_LOADED:-}" ]] && return 0
_UI_INPUT_LOADED=1

# Confirm dialog
# Usage: if ui_confirm "Are you sure?"; then ... fi
# Usage: ui_confirm "Continue?" --default=false
ui_confirm() {
    gum_confirm "$@"
}

# Single choice selection
# Usage: result=$(ui_choose "Option1" "Option2" "Option3")
ui_choose() {
    gum_exec choose "$@"
}

# Multi-choice selection
# Usage: result=$(ui_choose_multi "Option1" "Option2" "Option3")
ui_choose_multi() {
    gum_exec choose --no-limit "$@"
}

# Choice with header
# Usage: result=$(ui_choose_with_header "Select an option:" "Opt1" "Opt2")
ui_choose_with_header() {
    local header="$1"
    shift
    gum_exec choose --header "$header" "$@"
}

# Text input
# Usage: result=$(ui_input "Enter your name")
ui_input() {
    local placeholder="${1:-Enter text...}"
    shift || true
    gum_exec input --placeholder "$placeholder" "$@"
}

# Password input
# Usage: result=$(ui_password "Enter password")
ui_password() {
    local placeholder="${1:-Enter password...}"
    shift || true
    gum_exec input --password --placeholder "$placeholder" "$@"
}

# Multi-line text input
# Usage: result=$(ui_write "Enter description")
ui_write() {
    local placeholder="${1:-Enter text...}"
    shift || true
    gum_exec write --placeholder "$placeholder" "$@"
}

# Filter/search from list
# Usage: result=$(echo -e "item1\nitem2\nitem3" | ui_filter)
ui_filter() {
    gum_exec filter "$@"
}

# File picker
# Usage: result=$(ui_file "/path/to/dir")
ui_file() {
    local path="${1:-.}"
    shift || true
    gum_exec file "$path" "$@"
}

#######################################
# Enhanced input functions
#######################################

# Advanced text input with all options
# Usage: ui_input_ext --placeholder "Name" --value "default" --width 40 --header "Enter name:"
ui_input_ext() {
    gum_exec input "$@"
}

# Input with header
# Usage: result=$(ui_input_header "Enter your name:" "John Doe")
ui_input_header() {
    local header="$1"
    local placeholder="${2:-Enter text...}"
    shift 2 || shift || true
    gum_exec input --header "$header" --placeholder "$placeholder" "$@"
}

# Input with default value
# Usage: result=$(ui_input_value "default text" "Enter value")
ui_input_value() {
    local value="$1"
    local placeholder="${2:-Enter text...}"
    shift 2 || shift || true
    gum_exec input --value "$value" --placeholder "$placeholder" "$@"
}

# Write with header and dimensions
# Usage: ui_write_ext --header "Description" --width 80 --height 10
ui_write_ext() {
    gum_exec write "$@"
}

#######################################
# Enhanced choose functions
#######################################

# Choose with specific limit
# Usage: result=$(ui_choose_limit 2 "opt1" "opt2" "opt3" "opt4")
ui_choose_limit() {
    local limit=$1
    shift
    gum_exec choose --limit "$limit" "$@"
}

# Choose with pre-selected items (comma-separated)
# Usage: result=$(ui_choose_selected "opt2,opt3" "opt1" "opt2" "opt3" "opt4")
ui_choose_selected() {
    local selected="$1"
    shift
    gum_exec choose --selected "$selected" "$@"
}

# Choose with height limit
# Usage: result=$(ui_choose_height 5 "opt1" "opt2" ... "opt20")
ui_choose_height() {
    local height=$1
    shift
    gum_exec choose --height "$height" "$@"
}

# Filter with header
# Usage: result=$(echo -e "item1\nitem2" | ui_filter_header "Search items:")
ui_filter_header() {
    local header="$1"
    shift
    gum_exec filter --header "$header" "$@"
}

# File picker for directories only
# Usage: result=$(ui_dir "/path")
ui_dir() {
    local path="${1:-.}"
    shift || true
    gum_exec file --directory "$path" "$@"
}

# File picker showing hidden files
# Usage: result=$(ui_file_all "/path")
ui_file_all() {
    local path="${1:-.}"
    shift || true
    gum_exec file --all "$path" "$@"
}
