#!/usr/bin/env bash
# fzf.sh - Advanced fuzzy selection wrapper
# Wraps 'fzf' for selections with previews, falling back to 'gum filter'.
# shellcheck disable=SC2034,SC2155

[[ -n "${_EXT_FZF_LOADED:-}" ]] && return 0
_EXT_FZF_LOADED=1

# Source core/ui dependencies if needed
_EXT_FZF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_EXT_FZF_DIR/input.sh"

#######################################
# Advanced fuzzy select with preview
# Usage:
#   ui_fzf_select "Select file:" "cat {}" < file_list.txt
#   find . -maxdepth 2 | ui_fzf_select "Pick a file" "bat --color=always {}"
# Arguments:
#   $1 - Prompt text
#   $2 - Preview command (optional, uses '{}' placeholder)
# Stdin:
#   List of items to choose from
# Output:
#   Selected item (or empty if cancelled)
#######################################
ui_fzf_select() {
    local prompt="${1:-Select item:}"
    local preview_cmd="${2:-}"
    local selection=""

    # Check for fzf availability
    if command -v fzf &>/dev/null; then
        local fzf_opts=(
            --height=40%
            --layout=reverse
            --border
            --prompt="$prompt "
            --ansi
        )

        if [[ -n "$preview_cmd" ]]; then
            fzf_opts+=(--preview "$preview_cmd")
            fzf_opts+=(--preview-window="right:60%:wrap")
        fi

        # Run fzf, consuming stdin
        selection=$(fzf "${fzf_opts[@]}")
    else
        # Fallback to gum filter
        # Note: gum filter doesn't support previews, so that arg is ignored
        selection=$(gum filter --placeholder="$prompt" --height=20)
    fi

    echo "$selection"
}
