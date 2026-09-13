#!/usr/bin/env bash
# format.sh - Text formatting and rendering functions using gum
# shellcheck disable=SC2034

[[ -n "${_UI_FORMAT_LOADED:-}" ]] && return 0
_UI_FORMAT_LOADED=1

_UI_FORMAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_FORMAT_DIR/../../core/sh/gum_wrapper.sh"

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
# Returns 0 (pass) when the installed gum doesn't report a parseable semver
# version (e.g. a dev build that prints "version unknown (built from source)").
# No comparison is possible in that case, and failing hard would only break
# dev setups where gum is guaranteed current anyway.
ui_version_check() {
    local current
    current=$(gum --version 2>/dev/null | awk '{print $3}')
    if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        return 0
    fi

    gum_exec version-check "$@"
}
