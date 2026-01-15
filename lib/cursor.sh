#!/usr/bin/env bash
# cursor.sh - Cursor control functions
# Source this file for cursor manipulation utilities

# Prevent multiple sourcing
[[ -n "${_CURSOR_SH_LOADED:-}" ]] && return 0
_CURSOR_SH_LOADED=1

# Hide cursor
cursor_hide() {
    tput civis
}

# Show cursor
cursor_show() {
    tput cnorm
}

# Save cursor position (DEC)
cursor_save() {
    printf '\e7'
}

# Restore cursor position (DEC)
cursor_restore() {
    printf '\e8'
}

# Move cursor up N lines
cursor_up() {
    local n="${1:-1}"
    printf '\e[%dA' "$n"
}

# Move cursor down N lines
cursor_down() {
    local n="${1:-1}"
    printf '\e[%dB' "$n"
}

# Move cursor right N columns
cursor_right() {
    local n="${1:-1}"
    printf '\e[%dC' "$n"
}

# Move cursor left N columns
cursor_left() {
    local n="${1:-1}"
    printf '\e[%dD' "$n"
}

# Move cursor to column N (1-indexed)
cursor_column() {
    local col="${1:-1}"
    printf '\e[%dG' "$col"
}

# Move cursor to row,col (1-indexed)
cursor_goto() {
    local row="${1:-1}"
    local col="${2:-1}"
    printf '\e[%d;%dH' "$row" "$col"
}

# Clear from cursor to end of screen
clear_to_end() {
    printf '\e[J'
}

# Clear from cursor to end of line
clear_line_to_end() {
    printf '\e[K'
}

# Clear entire line
clear_line() {
    printf '\e[2K'
}
