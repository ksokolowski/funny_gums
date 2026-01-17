#!/usr/bin/env bash
# system.sh - System module loader
# Sources all system submodules for hardware monitoring
# shellcheck disable=SC1091

[[ -n "${_SYSTEM_LOADED:-}" ]] && return 0
_SYSTEM_LOADED=1

_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all system submodules
source "$_SYSTEM_DIR/base.sh"      # Common utilities (format_bytes, etc.)
source "$_SYSTEM_DIR/inxi.sh"      # Inxi caching and parsing
source "$_SYSTEM_DIR/cpu.sh"       # CPU metrics
source "$_SYSTEM_DIR/memory.sh"    # Memory/swap metrics
source "$_SYSTEM_DIR/storage.sh"   # Storage/disk metrics
source "$_SYSTEM_DIR/gpu.sh"       # GPU metrics
source "$_SYSTEM_DIR/network.sh"   # Network interface info
