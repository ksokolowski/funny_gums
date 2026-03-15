#!/usr/bin/env bash
# progress.sh - Spinner and layout composition functions using gum
# shellcheck disable=SC2034

_UI_PROGRESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_PROGRESS_DIR/../../core/sh/gum_wrapper.sh"

[[ -n "${_UI_PROGRESS_LOADED:-}" ]] && return 0
_UI_PROGRESS_LOADED=1

# Spinner while command runs
# Usage: ui_spin "Loading..." command args...
# Usage: ui_spin "Loading..." --spinner dot -- command args...
ui_spin() {
    local title="$1"
    shift
    gum_exec spin --title "$title" -- "$@"
}

# Spinner with type selection
# Types: line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger
# Usage: ui_spin_type dot "Loading..." command args...
ui_spin_type() {
    local spinner_type="$1"
    local title="$2"
    shift 2
    gum_exec spin --spinner "$spinner_type" --title "$title" -- "$@"
}

# Spinner showing command output
# Usage: ui_spin_output "Building..." make build
ui_spin_output() {
    local title="$1"
    shift
    gum_exec spin --show-output --title "$title" -- "$@"
}

# Join text horizontally
# Usage: ui_join_h "text1" "text2"
ui_join_h() {
    gum_exec join --horizontal "$@"
}

# Join text vertically
# Usage: ui_join_v "text1" "text2"
ui_join_v() {
    gum_exec join --vertical "$@"
}
