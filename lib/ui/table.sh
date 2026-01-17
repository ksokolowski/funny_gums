#!/usr/bin/env bash
# table.sh - Table and pager functions using gum
# shellcheck disable=SC2034

[[ -n "${_UI_TABLE_LOADED:-}" ]] && return 0
_UI_TABLE_LOADED=1

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
