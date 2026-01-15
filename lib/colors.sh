#!/usr/bin/env bash
# colors.sh - ANSI color definitions for terminal output
# Source this file to use color variables in your scripts
# shellcheck disable=SC2034 # Variables are exported for external use

# Prevent multiple sourcing
[[ -n "${_COLORS_SH_LOADED:-}" ]] && return 0
_COLORS_SH_LOADED=1

# Basic colors
BLACK=$'\e[30m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
MAGENTA=$'\e[35m'
CYAN=$'\e[36m'
WHITE=$'\e[37m'

# Bright colors
BRIGHT_BLACK=$'\e[90m'
BRIGHT_RED=$'\e[91m'
BRIGHT_GREEN=$'\e[92m'
BRIGHT_YELLOW=$'\e[93m'
BRIGHT_BLUE=$'\e[94m'
BRIGHT_MAGENTA=$'\e[95m'
BRIGHT_CYAN=$'\e[96m'
BRIGHT_WHITE=$'\e[97m'

# Background colors
BG_BLACK=$'\e[40m'
BG_RED=$'\e[41m'
BG_GREEN=$'\e[42m'
BG_YELLOW=$'\e[43m'
BG_BLUE=$'\e[44m'
BG_MAGENTA=$'\e[45m'
BG_CYAN=$'\e[46m'
BG_WHITE=$'\e[47m'

# Text styles
BOLD=$'\e[1m'
DIM=$'\e[2m'
ITALIC=$'\e[3m'
UNDERLINE=$'\e[4m'
BLINK=$'\e[5m'
REVERSE=$'\e[7m'
HIDDEN=$'\e[8m'
STRIKETHROUGH=$'\e[9m'

# Reset
RESET=$'\e[0m'

# Helper function to colorize text
colorize() {
    local color="$1"
    shift
    echo -e "${color}$*${RESET}"
}
