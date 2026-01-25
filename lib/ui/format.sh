#!/usr/bin/env bash
# format.sh - Text formatting and rendering functions using gum
# shellcheck disable=SC2034

_UI_FORMAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_FORMAT_DIR/../core/gum_wrapper.sh"

[[ -n "${_UI_FORMAT_LOADED:-}" ]] && return 0
_UI_FORMAT_LOADED=1

# Format/render markdown text
# Usage: echo "# Title" | ui_format
# Usage: ui_format "# Hello\n- Item 1\n- Item 2"
ui_format() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format
    else
        gum_exec format
    fi
}

# Format code with syntax highlighting
# Usage: cat script.sh | ui_format_code
# Usage: ui_format_code "func main() { }"
ui_format_code() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format --type code
    else
        gum_exec format --type code
    fi
}

# Format text with emoji parsing (:emoji: -> emoji)
# Usage: echo "I :heart: bash" | ui_format_emoji
# Usage: ui_format_emoji "Hello :wave:"
ui_format_emoji() {
    if [[ $# -gt 0 ]]; then
        echo -e "$*" | gum format --type emoji
    else
        gum_exec format --type emoji
    fi
}

# Format with template (Go template syntax)
# Usage: echo '{{ Bold "Hello" }}' | ui_format_template
ui_format_template() {
    if [[ $# -gt 0 && "$1" != -* ]]; then
        echo -e "$*" | gum format --type template
    else
        gum_exec format --type template "$@"
    fi
}

# Version check
# Usage: ui_version_check ">= 0.17.0"
ui_version_check() {
    gum_exec version-check "$@"
}
