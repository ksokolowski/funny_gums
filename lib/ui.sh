#!/usr/bin/env bash
# ui.sh - UI helper functions using gum
# Source this file for common UI patterns

# Prevent multiple sourcing
[[ -n "${_UI_SH_LOADED:-}" ]] && return 0
_UI_SH_LOADED=1

# Show styled box with title and content
# Usage: ui_box "Title" "line1" "line2" ...
ui_box() {
    gum style --no-strip-ansi --border rounded --border-foreground 6 --padding "1 2" "$@"
}

# Show styled box with double border
# Usage: ui_box_double "Title" "line1" "line2" ...
ui_box_double() {
    gum style --no-strip-ansi --border double --border-foreground 6 --padding "1 2" "$@"
}

# Show success message
# Usage: ui_success "Message"
ui_success() {
    gum style --no-strip-ansi --border rounded --border-foreground 2 --padding "1 4" --align center "$@"
}

# Show error message
# Usage: ui_error "Message"
ui_error() {
    gum style --no-strip-ansi --border rounded --border-foreground 1 --padding "1 4" --align center "$@"
}

# Show warning message
# Usage: ui_warn "Message"
ui_warn() {
    gum style --no-strip-ansi --border rounded --border-foreground 3 --padding "1 4" --align center "$@"
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
    gum choose "$@"
}

# Multi-choice selection
# Usage: result=$(ui_choose_multi "Option1" "Option2" "Option3")
ui_choose_multi() {
    gum choose --no-limit "$@"
}

# Choice with header
# Usage: result=$(ui_choose_with_header "Select an option:" "Opt1" "Opt2")
ui_choose_with_header() {
    local header="$1"
    shift
    gum choose --header "$header" "$@"
}

# Text input
# Usage: result=$(ui_input "Enter your name")
ui_input() {
    local placeholder="${1:-Enter text...}"
    shift || true
    gum input --placeholder "$placeholder" "$@"
}

# Password input
# Usage: result=$(ui_password "Enter password")
ui_password() {
    local placeholder="${1:-Enter password...}"
    shift || true
    gum input --password --placeholder "$placeholder" "$@"
}

# Multi-line text input
# Usage: result=$(ui_write "Enter description")
ui_write() {
    local placeholder="${1:-Enter text...}"
    shift || true
    gum write --placeholder "$placeholder" "$@"
}

# Filter/search from list
# Usage: result=$(echo -e "item1\nitem2\nitem3" | ui_filter)
ui_filter() {
    gum filter "$@"
}

# File picker
# Usage: result=$(ui_file "/path/to/dir")
ui_file() {
    local path="${1:-.}"
    shift || true
    gum file "$path" "$@"
}

# Spinner while command runs
# Usage: ui_spin "Loading..." command args...
# Usage: ui_spin "Loading..." --spinner dot -- command args...
ui_spin() {
    local title="$1"
    shift
    gum spin --title "$title" -- "$@"
}

# Spinner with type selection
# Types: line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger
# Usage: ui_spin_type dot "Loading..." command args...
ui_spin_type() {
    local spinner_type="$1"
    local title="$2"
    shift 2
    gum spin --spinner "$spinner_type" --title "$title" -- "$@"
}

# Spinner showing command output
# Usage: ui_spin_output "Building..." make build
ui_spin_output() {
    local title="$1"
    shift
    gum spin --show-output --title "$title" -- "$@"
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

#######################################
# Format functions (markdown, code, emoji)
#######################################

# Format/render markdown text
# Usage: echo "# Title" | ui_format
# Usage: ui_format "# Hello\n- Item 1\n- Item 2"
ui_format() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format
    else
        gum format
    fi
}

# Format code with syntax highlighting
# Usage: cat script.sh | ui_format_code
# Usage: ui_format_code "func main() { }"
ui_format_code() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format --type code
    else
        gum format --type code
    fi
}

# Format text with emoji parsing (:emoji: -> 🎉)
# Usage: echo "I :heart: bash" | ui_format_emoji
# Usage: ui_format_emoji "Hello :wave:"
ui_format_emoji() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format --type emoji
    else
        gum format --type emoji
    fi
}

# Format with template (Go template syntax)
# Usage: echo '{{ Bold "Hello" }}' | ui_format_template
ui_format_template() {
    if [[ $# -gt 0 && "$1" != -* ]]; then
        echo -e "$*" | gum format --type template
    else
        gum format --type template "$@"
    fi
}

# Version check
# Usage: ui_version_check ">= 0.17.0"
ui_version_check() {
    gum version-check "$@"
}

#######################################
# Table functions
#######################################

# Display interactive table from CSV/TSV data
# Usage: cat data.csv | ui_table
# Usage: ui_table --separator "," --columns "Name,Age,City" < data.csv
# Usage: ui_table --border rounded --file data.csv
ui_table() {
    gum table "$@"
}

# Display table from file
# Usage: ui_table_file data.csv
# Usage: ui_table_file data.csv --separator ","
ui_table_file() {
    local file="$1"
    shift
    gum table --file "$file" "$@"
}

# Display table with custom columns
# Usage: ui_table_columns "Name,Age" < data.csv
ui_table_columns() {
    local columns="$1"
    shift
    gum table --columns "$columns" "$@"
}

#######################################
# Pager functions
#######################################

# Scrollable text viewer
# Usage: cat README.md | ui_pager
# Usage: ui_pager < longfile.txt
ui_pager() {
    gum pager "$@"
}

# Pager with line numbers
# Usage: cat script.sh | ui_pager_numbered
ui_pager_numbered() {
    gum pager --show-line-numbers "$@"
}

# Pager with soft wrap
# Usage: cat longlines.txt | ui_pager_wrap
ui_pager_wrap() {
    gum pager --soft-wrap "$@"
}

#######################################
# Enhanced input functions
#######################################

# Advanced text input with all options
# Usage: ui_input_ext --placeholder "Name" --value "default" --width 40 --header "Enter name:"
ui_input_ext() {
    gum input "$@"
}

# Input with header
# Usage: result=$(ui_input_header "Enter your name:" "John Doe")
ui_input_header() {
    local header="$1"
    local placeholder="${2:-Enter text...}"
    shift 2 || shift || true
    gum input --header "$header" --placeholder "$placeholder" "$@"
}

# Input with default value
# Usage: result=$(ui_input_value "default text" "Enter value")
ui_input_value() {
    local value="$1"
    local placeholder="${2:-Enter text...}"
    shift 2 || shift || true
    gum input --value "$value" --placeholder "$placeholder" "$@"
}

# Write with header and dimensions
# Usage: ui_write_ext --header "Description" --width 80 --height 10
ui_write_ext() {
    gum write "$@"
}

#######################################
# Enhanced choose functions
#######################################

# Choose with specific limit
# Usage: result=$(ui_choose_limit 2 "opt1" "opt2" "opt3" "opt4")
ui_choose_limit() {
    local limit=$1
    shift
    gum choose --limit "$limit" "$@"
}

# Choose with pre-selected items (comma-separated)
# Usage: result=$(ui_choose_selected "opt2,opt3" "opt1" "opt2" "opt3" "opt4")
ui_choose_selected() {
    local selected="$1"
    shift
    gum choose --selected "$selected" "$@"
}

# Choose with height limit
# Usage: result=$(ui_choose_height 5 "opt1" "opt2" ... "opt20")
ui_choose_height() {
    local height=$1
    shift
    gum choose --height "$height" "$@"
}

# Filter with header
# Usage: result=$(echo -e "item1\nitem2" | ui_filter_header "Search items:")
ui_filter_header() {
    local header="$1"
    shift
    gum filter --header "$header" "$@"
}

# File picker for directories only
# Usage: result=$(ui_dir "/path")
ui_dir() {
    local path="${1:-.}"
    shift || true
    gum file --directory "$path" "$@"
}

# File picker showing hidden files
# Usage: result=$(ui_file_all "/path")
ui_file_all() {
    local path="${1:-.}"
    shift || true
    gum file --all "$path" "$@"
}
