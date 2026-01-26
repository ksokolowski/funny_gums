#!/usr/bin/env bash
# funny_gums.sh - Entry point for Funny Gums library
# Source this file to load all modules at once
#
# Usage:
#   source /path/to/funny_gums.sh
#
# Or source individual modules from lib/ as needed:
#   source /path/to/lib/core/colors.sh      # ANSI colors
#   source /path/to/lib/ui/ui.sh            # All UI components
#   source /path/to/lib/system/system.sh    # All system monitoring
#   source /path/to/lib/dashboard/dashboard.sh
#
# shellcheck disable=SC1091

# Prevent multiple sourcing
[[ -n "${_FUNNY_GUMS_LOADED:-}" ]] && return 0
_FUNNY_GUMS_LOADED=1

# Get library directory
_FUNNY_GUMS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_FUNNY_GUMS_LIB="$_FUNNY_GUMS_DIR/lib"

# Source all modules in dependency order

# Core modules (no dependencies)
source "$_FUNNY_GUMS_LIB/core/colors.sh"
source "$_FUNNY_GUMS_LIB/core/cursor.sh"
source "$_FUNNY_GUMS_LIB/core/spinner.sh"
source "$_FUNNY_GUMS_LIB/core/logging.sh"
source "$_FUNNY_GUMS_LIB/core/sudo.sh"
source "$_FUNNY_GUMS_LIB/core/terminal.sh"
source "$_FUNNY_GUMS_LIB/core/emoji_data.sh"
source "$_FUNNY_GUMS_LIB/core/emoji_registry.sh"
source "$_FUNNY_GUMS_LIB/core/emojis.sh"
source "$_FUNNY_GUMS_LIB/core/text.sh"

# Terminal capability is detected by emoji_registry.sh on source
# Re-export emoji vars after all modules loaded
_export_emoji_vars

# UI modules (depends on core/colors)
source "$_FUNNY_GUMS_LIB/ui/ui.sh"

# Dashboard modules (depends on core/colors, cursor, spinner)
source "$_FUNNY_GUMS_LIB/dashboard/dashboard.sh"
source "$_FUNNY_GUMS_LIB/dashboard/runner.sh"

# System modules (optional - for hardware monitoring)
source "$_FUNNY_GUMS_LIB/system/system.sh"
