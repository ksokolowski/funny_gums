#!/usr/bin/env bash
# viewer.sh - Smart file viewer wrapper (bat -> glow -> gum -> cat)
# shellcheck disable=SC2034,SC2155

[[ -n "${_EXT_VIEWER_LOADED:-}" ]] && return 0
_EXT_VIEWER_LOADED=1

# Source dependencies
_EXT_VIEWER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_EXT_VIEWER_DIR/table.sh" # for ui_pager

#######################################
# View a file with best available tool
# Usage: ui_view_file "README.md" ["markdown"]
#######################################
ui_view_file() {
    local file="$1"
    local syntax="${2:-}"

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file" >&2
        return 1
    fi

    # 1. Try 'bat' (Best for code/config/general text)
    if command -v bat &>/dev/null; then
        local style="numbers,changes,header"
        # If syntax provided, force it
        if [[ -n "$syntax" ]]; then
            bat --style="$style" --color=always --language="$syntax" "$file" --paging=always
            return 0
        else
            bat --style="$style" --color=always "$file" --paging=always
            return 0
        fi
    fi

    # 2. Try 'glow' (Specific for markdown)
    if [[ "$file" == *.md ]] || [[ "$syntax" == "markdown" ]]; then
        if command -v glow &>/dev/null; then
            glow --pager "$file"
            return 0
        fi
    fi

    # 3. Fallback to 'gum format' (Markdown) if applicable
    if [[ "$file" == *.md ]] || [[ "$syntax" == "markdown" ]]; then
        local formatted
        formatted=$(gum format <"$file") || return 1
        echo "$formatted" | ui_pager
        return $?
    fi

    # 4. Fallback to generic pager
    ui_pager <"$file"
}
