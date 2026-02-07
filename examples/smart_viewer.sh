#!/usr/bin/env bash
#
# smart_viewer.sh - Demonstrates ui_fzf_select and ui_view_file
#
# This script lists files in the current repository, allows fuzzy selection
# with a live preview (bat/glow), and opens them in a pager.
#
# Usage: ./smart_viewer.sh

set -uo pipefail
_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the main library
source "$_DIR/../funny_gums.sh"

# Source the viewer and fzf extensions
source "$_DIR/../lib/ui/interaction/fzf.sh"
source "$_DIR/../lib/ui/widgets/viewer.sh"

main() {
    # Check dependencies for full experience
    if ! command -v bat &>/dev/null; then
        ui_box --border double --border-foreground 208 \
            "Note: 'bat' is not installed." \
            "Install it for syntax highlighting and previews."
        sleep 2
    fi

    clear
    ui_box "Smart Viewer" "Select a file to view content." --border rounded

    # Search in library and examples
    local search_path="$_DIR/.."

    # Let user select a file
    # ui_fzf_select handles the preview logic internally if data is piped to it
    local selected_file

    # We construct a preview command that fits the files we are looking for
    # Using 'bat' for color preview if available, else cat
    local preview_cmd="cat {}"
    if command -v bat &>/dev/null; then
        preview_cmd="bat --style=numbers --color=always --line-range :50 {}"
    fi

    # Using 'find' to list files, piping to ui_fzf_select
    # We strip the leading ./ for cleaner display
    # We use sed to make paths relative to the project root for display clarity
    selected_file=$(find "$search_path" -maxdepth 3 -type f -name "*.sh" -o -name "*.md" |
        grep -v "/.git/" |
        ui_fzf_select "Pick a file to inspect:" "$preview_cmd")

    if [[ -z "$selected_file" ]]; then
        ui_text "${EMOJI_WARNING} No file selected."
        exit 0
    fi

    # View the file using smart viewer
    # Auto-detects markdown vs code
    ui_view_file "$selected_file"
}

main "$@"
