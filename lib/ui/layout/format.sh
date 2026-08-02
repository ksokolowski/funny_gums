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
ui_version_check() {
    # Extract a semantic version from `gum --version` when possible and
    # perform the constraint check locally. If no semver can be extracted
    # (e.g. output "unknown"), fall back to success to avoid spurious
    # failures in build environments.
    local raw gv semver op ver cmp
    raw=$(gum --version 2>/dev/null || echo "")
    # Extract first semver-like token (major.minor or major.minor.patch)
    semver=$(printf '%s' "$raw" | grep -oE '[0-9]+(\.[0-9]+){1,2}' | head -n1 || true)

    # If we couldn't extract a semver, fall back to previous behaviour
    [[ -z "$semver" ]] && return 0

    # Parse constraint passed by caller (e.g. ">= 0.17.0"). Default to >= if
    # not provided in a recognizable form.
    raw="$*"
    if [[ "$raw" =~ ^([><=]{1,2})[[:space:]]*([0-9].*)$ ]]; then
        op="${BASH_REMATCH[1]}"
        ver="${BASH_REMATCH[2]}"
    else
        # If multiple args were provided, join them and try again
        if [[ $# -gt 0 ]]; then
            raw="$*"
            if [[ "$raw" =~ ^([><=]{1,2})[[:space:]]*([0-9].*)$ ]]; then
                op="${BASH_REMATCH[1]}"
                ver="${BASH_REMATCH[2]}"
            else
                op=">="
                ver="$raw"
            fi
        else
            # No constraint provided; consider it satisfied
            return 0
        fi
    fi

    # Normalize versions to numeric triplets
    _sv_to_nums() {
        local s="$1" a b c
        s="${s%%[-+]*}" # strip pre-release/build suffixes
        IFS='.' read -r a b c <<<"$s"
        a=${a:-0}; b=${b:-0}; c=${c:-0}
        printf '%d %d %d' "$a" "$b" "$c"
    }

    _semver_cmp() {
        # echo -1 if a<b, 0 if equal, 1 if a>b
        local a1 a2 a3 b1 b2 b3
        read -r a1 a2 a3 <<<"$(_sv_to_nums "$1")"
        read -r b1 b2 b3 <<<"$(_sv_to_nums "$2")"
        if (( a1 < b1 )); then echo -1; return; fi
        if (( a1 > b1 )); then echo 1; return; fi
        if (( a2 < b2 )); then echo -1; return; fi
        if (( a2 > b2 )); then echo 1; return; fi
        if (( a3 < b3 )); then echo -1; return; fi
        if (( a3 > b3 )); then echo 1; return; fi
        echo 0
    }

    cmp=$(_semver_cmp "$semver" "$ver")

    case "$op" in
        ">=") [[ $cmp -ge 0 ]] && return 0 || return 1 ;; 
        "<=") [[ $cmp -le 0 ]] && return 0 || return 1 ;; 
        ">")  [[ $cmp -gt 0 ]] && return 0 || return 1 ;; 
        "<")  [[ $cmp -lt 0 ]] && return 0 || return 1 ;; 
        "="|"==") [[ $cmp -eq 0 ]] && return 0 || return 1 ;; 
        *)
            # Unknown operator — delegate to gum
            gum_exec version-check "$@" ;;
    esac
}
