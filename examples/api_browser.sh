#!/usr/bin/env bash
#
# api_browser.sh - Demonstrates net_get_json and ui_table integration
#
# This script fetches a TODO list from jsonplaceholder.typicode.com,
# parses the JSON into CSV format using jq, and displays it in an
# interactive table using ui_table.
#
# Usage: ./api_browser.sh

set -uo pipefail
_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the main library
source "$_DIR/../funny_gums.sh"

# Source the newly added extensions
# (Note: These are not loaded by default to keep start-up light)
source "$_DIR/../lib/core/sh/http.sh"

main() {
    # Check for external dependencies required for this specific script
    if ! command -v jq &>/dev/null; then
        ui_box "Error: 'jq' is required for this example to parse JSON." --border-foreground 196
        return 1
    fi

    echo ""
    ui_box "API Browser Example" "Fetching data from jsonplaceholder..." --border rounded --padding "0 1"

    local api_url="https://jsonplaceholder.typicode.com/todos?_limit=10"

    # 1. Fetch JSON data
    # net_get_json handles the spinner and error checking
    local json_data
    if ! json_data=$(net_get_json "$api_url"); then
        ui_box "Failed to fetch data!" --border-foreground 196
        exit 1
    fi

    # 2. Convert JSON to CSV for the table
    # We select ID, Title, and Completed status
    local csv_data
    csv_data=$(echo "$json_data" | jq -r '["ID", "User", "Title", "Completed"], (.[] | [.id, .userId, .title, .completed]) | @csv')

    # 3. Display in a table
    echo ""
    ui_text "Data fetched successfully! Parsing to table..."
    echo ""

    # We pipe the CSV data to ui_table
    echo "$csv_data" | ui_table --border rounded --columns "ID,User,Title,Completed" --widths "4,6,40,10"

    # 4. Error handling demo
    echo ""
    ui_text "Now attempting to fetch a broken URL to demonstrate error handling..."
    if ! net_get_json "https://jsonplaceholder.typicode.com/invalid-endpoint-404"; then
        echo "" # spacing
        ui_text "${EMOJI_SUCCESS} Correctly caught the error as expected!"
        ui_text "  (The error above is from the library logging)"
    fi
}

main "$@"
