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
source "$_FUNNY_GUMS_LIB/core/term/colors.sh"
source "$_FUNNY_GUMS_LIB/core/sh/deps.sh"
source "$_FUNNY_GUMS_LIB/core/term/cursor.sh"
source "$_FUNNY_GUMS_LIB/ui/widgets/spinner.sh"

# Enforce core dependencies immediately
dep_require_all "gum" "jq" "awk" "sed" "grep" "date"
source "$_FUNNY_GUMS_LIB/core/sh/logging.sh"
source "$_FUNNY_GUMS_LIB/core/sh/sudo.sh"
source "$_FUNNY_GUMS_LIB/core/term/terminal.sh"
source "$_FUNNY_GUMS_LIB/core/text/emoji_data.sh"
source "$_FUNNY_GUMS_LIB/core/text/emoji_registry.sh"
source "$_FUNNY_GUMS_LIB/core/text/emojis.sh"
source "$_FUNNY_GUMS_LIB/core/text/text.sh"

# Terminal capability is detected by emoji_registry.sh on source
# Re-export emoji vars after all modules loaded
_export_emoji_vars

# UI modules (depends on core/colors)
source "$_FUNNY_GUMS_LIB/ui/layout/ui.sh"

# Dashboard modules (depends on core/colors, cursor, spinner)
source "$_FUNNY_GUMS_LIB/app/dashboard.sh"
source "$_FUNNY_GUMS_LIB/app/runner.sh"

# System modules (hardware monitoring and parsing)
source "$_FUNNY_GUMS_LIB/mod/os/system.sh"

# Extended modules (optional standard library extensions)
# These degrade gracefully if tools (fzf, bat, curl) are missing
source "$_FUNNY_GUMS_LIB/ui/interaction/fzf.sh"
source "$_FUNNY_GUMS_LIB/core/sh/http.sh"
source "$_FUNNY_GUMS_LIB/ui/widgets/viewer.sh"
