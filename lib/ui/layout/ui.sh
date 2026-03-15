#!/usr/bin/env bash
# ui.sh - UI module loader
# Sources all UI submodules in correct dependency order
# shellcheck disable=SC1091

[[ -n "${_UI_LOADED:-}" ]] && return 0
_UI_LOADED=1

_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all UI submodules
source "$_UI_DIR/base.sh"
source "$_UI_DIR/../interaction/input.sh"
source "$_UI_DIR/format.sh"
source "$_UI_DIR/../widgets/table.sh"
source "$_UI_DIR/../widgets/progress.sh"
source "$_UI_DIR/../widgets/gauge.sh"
source "$_UI_DIR/../widgets/spinner.sh"
source "$_UI_DIR/../widgets/viewer.sh"
source "$_UI_DIR/../interaction/fzf.sh"
source "$_UI_DIR/../../mod/storage/ui.sh"
source "$_UI_DIR/../../mod/net/ui.sh"
