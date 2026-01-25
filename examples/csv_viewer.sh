#!/usr/bin/env bash
# csv_viewer.sh - Interactive CSV data explorer
# Demonstrates: ui_table, ui_filter, ui_pager, ui_file, ui_confirm
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
source "$LIB_DIR/core/terminal.sh"
source "$LIB_DIR/core/text.sh"
source "$LIB_DIR/core/emojis.sh"
source "$LIB_DIR/ui/ui.sh"

# Detect terminal mode for VS16 emoji support
detect_terminal_mode

############################
# FUNCTIONS
############################
show_help() {
    ui_box "📊 CSV Viewer" \
        "" \
        "Interactive CSV/TSV data explorer" \
        "" \
        "Usage: csv_viewer.sh [file.csv]" \
        "" \
        "If no file provided, a file picker will open."
}

detect_separator() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file")
    
    # Count occurrences
    local tabs commas semicolons
    tabs=$(echo "$first_line" | tr -cd '\t' | wc -c)
    commas=$(echo "$first_line" | tr -cd ',' | wc -c)
    semicolons=$(echo "$first_line" | tr -cd ';' | wc -c)
    
    if ((tabs > commas && tabs > semicolons)); then
        echo $'\t'
    elif ((semicolons > commas)); then
        echo ";"
    else
        echo ","
    fi
}

############################
# MAIN
############################
CSV_FILE=""

# Get file from argument or picker
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    CSV_FILE="$1"
else
    echo ""
    ui_info "Select a CSV/TSV file to view:"
    CSV_FILE=$(ui_file ".")
fi

# Validate file
if [[ -z "$CSV_FILE" ]]; then
    ui_info "No file selected."
    exit 0
fi

if [[ ! -f "$CSV_FILE" ]]; then
    ui_error "File not found: $CSV_FILE"
    exit 1
fi

# Show file info
echo ""
filename=$(basename "$CSV_FILE")
lines=$(wc -l < "$CSV_FILE")
size=$(du -h "$CSV_FILE" | cut -f1)

ui_box "📄 File: $filename" \
    "" \
    "Lines: $lines" \
    "Size: $size"

# Detect separator
separator=$(detect_separator "$CSV_FILE")
sep_name="comma"
[[ "$separator" == $'\t' ]] && sep_name="tab"
[[ "$separator" == ";" ]] && sep_name="semicolon"
echo ""
ui_info "Detected separator: $sep_name"

############################
# MAIN MENU LOOP
############################
while true; do
    echo ""
    action=$(ui_choose_with_header "What would you like to do?" \
        "📊 View table" \
        "🔍 Filter/search rows" \
        "📝 View raw content" \
        "📈 Show statistics" \
        "❌ Exit")
    
    case "$action" in
        "📊 View table")
            echo ""
            ui_table --separator "$separator" < "$CSV_FILE"
            ;;
        
        "🔍 Filter/search rows")
            echo ""
            ui_info "Type to filter rows (fuzzy search):"
            selected=$(ui_filter --header "Search rows:" < "$CSV_FILE")
            if [[ -n "$selected" ]]; then
                echo ""
                ui_box "Selected Row" "" "$selected"
            fi
            ;;
        
        "📝 View raw content")
            echo ""
            ui_pager_numbered < "$CSV_FILE"
            ;;
        
        "📈 Show statistics")
            echo ""
            # Get column count from header
            header=$(head -1 "$CSV_FILE")
            if [[ "$separator" == $'\t' ]]; then
                col_count=$(echo "$header" | awk -F'\t' '{print NF}')
            else
                col_count=$(echo "$header" | awk -F"$separator" '{print NF}')
            fi
            
            ui_box "📈 Statistics" \
                "" \
                "Columns: $col_count" \
                "Rows: $((lines - 1)) (excluding header)" \
                "Total lines: $lines" \
                "" \
                "Header: $header"
            ;;
        
        "❌ Exit"|"")
            ui_info "Goodbye!"
            exit 0
            ;;
    esac
done
