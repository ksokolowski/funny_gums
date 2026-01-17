#!/usr/bin/env bash
# markdown_preview.sh - Markdown file preview with syntax highlighting
# Demonstrates: ui_format, ui_pager, ui_file, ui_format_code
# shellcheck disable=SC1091
set -u

############################
# SCRIPT CONFIGURATION
############################
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source library
source "$LIB_DIR/core/colors.sh"
source "$LIB_DIR/ui/ui.sh"

############################
# FUNCTIONS
############################
show_help() {
    ui_box "📖 Markdown Preview" \
        "" \
        "Preview markdown files with formatting" \
        "" \
        "Usage: markdown_preview.sh [file.md]" \
        "" \
        "Supports:" \
        "  • Markdown rendering" \
        "  • Code syntax highlighting" \
        "  • Emoji parsing"
}

preview_file() {
    local file="$1"
    local content
    content=$(cat "$file")
    
    echo ""
    ui_info "Rendering: $(basename "$file")"
    echo ""
    
    # Render markdown and pipe to pager
    echo "$content" | ui_format | ui_pager
}

############################
# MAIN
############################
MD_FILE=""

# Get file from argument or picker
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    MD_FILE="$1"
else
    echo ""
    ui_box "📖 Markdown Preview" \
        "" \
        "Select a markdown file to preview"
    echo ""
    ui_info "Choose a file:"
    MD_FILE=$(ui_file ".")
fi

# Validate file
if [[ -z "$MD_FILE" ]]; then
    ui_info "No file selected."
    exit 0
fi

if [[ ! -f "$MD_FILE" ]]; then
    ui_error "File not found: $MD_FILE"
    exit 1
fi

############################
# MAIN MENU LOOP
############################
while true; do
    filename=$(basename "$MD_FILE")
    
    echo ""
    action=$(ui_choose_with_header "📖 $filename - What would you like to do?" \
        "📄 Preview formatted" \
        "💻 View as code (syntax highlighted)" \
        "😀 Preview with emoji parsing" \
        "📝 View raw content" \
        "📂 Open different file" \
        "❌ Exit")
    
    case "$action" in
        "📄 Preview formatted")
            echo ""
            ui_format < "$MD_FILE" | ui_pager
            ;;
        
        "💻 View as code (syntax highlighted)")
            echo ""
            ui_format_code < "$MD_FILE" | ui_pager
            ;;
        
        "😀 Preview with emoji parsing")
            echo ""
            ui_format_emoji < "$MD_FILE" | ui_pager
            ;;
        
        "📝 View raw content")
            echo ""
            ui_pager_numbered < "$MD_FILE"
            ;;
        
        "📂 Open different file")
            echo ""
            ui_info "Choose a file:"
            new_file=$(ui_file ".")
            if [[ -n "$new_file" && -f "$new_file" ]]; then
                MD_FILE="$new_file"
            fi
            ;;
        
        "❌ Exit"|"")
            ui_info "Goodbye!"
            exit 0
            ;;
    esac
done
