#!/usr/bin/env bash
# my_gums.sh - Entry point for my_gums library
# Source this file to load all modules at once
#
# Usage:
#   source /path/to/my_gums.sh
#
# Or source individual modules from lib/ as needed
# shellcheck disable=SC1091

# Prevent multiple sourcing
[[ -n "${_MY_GUMS_LOADED:-}" ]] && return 0
_MY_GUMS_LOADED=1

# Get library directory
_MY_GUMS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_MY_GUMS_LIB="$_MY_GUMS_DIR/lib"

# Source all modules in dependency order
# Level 0: No dependencies
source "$_MY_GUMS_LIB/colors.sh"
source "$_MY_GUMS_LIB/cursor.sh"
source "$_MY_GUMS_LIB/spinner.sh"
source "$_MY_GUMS_LIB/logging.sh"
source "$_MY_GUMS_LIB/sudo.sh"
source "$_MY_GUMS_LIB/ui.sh"

# Level 1: Depends on colors, cursor, spinner
source "$_MY_GUMS_LIB/dashboard.sh"

# Level 2: Depends on dashboard, spinner, logging
source "$_MY_GUMS_LIB/runner.sh"
