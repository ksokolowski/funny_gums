#!/usr/bin/env bash
# ui.sh - UI module loader
# Sources all UI submodules in correct dependency order
# shellcheck disable=SC1091

[[ -n "${_UI_LOADED:-}" ]] && return 0
_UI_LOADED=1

_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all UI submodules
source "$_UI_DIR/base.sh"
source "$_UI_DIR/input.sh"
source "$_UI_DIR/format.sh"
source "$_UI_DIR/table.sh"
source "$_UI_DIR/progress.sh"
source "$_UI_DIR/gauge.sh"      # Depends on core/colors.sh
source "$_UI_DIR/storage.sh"    # Depends on gauge.sh
source "$_UI_DIR/network.sh"    # Depends on gauge.sh
