#!/usr/bin/env bash
# system.sh - System module loader
# Sources all system submodules for hardware monitoring
# shellcheck disable=SC1091

[[ -n "${_SYSTEM_LOADED:-}" ]] && return 0
_SYSTEM_LOADED=1

_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source CLI tool abstraction modules first (no dependencies on other system modules)
# Source all system submodules
_SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_SYSTEM_DIR/../hw/sensors.sh"       # lm-sensors abstraction
source "$_SYSTEM_DIR/lspci.sh"               # PCI device queries
source "$_SYSTEM_DIR/../storage/smartctl.sh" # Drive health (SMART + NVMe)
source "$_SYSTEM_DIR/../hw/nvidia.sh"        # NVIDIA GPU queries
source "$_SYSTEM_DIR/../hw/amd.sh"           # AMD GPU queries
source "$_SYSTEM_DIR/../storage/hdparm.sh"   # Disk parameters
source "$_SYSTEM_DIR/dmidecode.sh"           # BIOS/motherboard info
source "$_SYSTEM_DIR/power.sh"               # Battery/AC power

# Domain modules (depend on the ones above)
source "$_SYSTEM_DIR/base.sh"               # Common utilities (format_bytes, etc.)
source "$_SYSTEM_DIR/inxi.sh"               # Inxi caching and parsing
source "$_SYSTEM_DIR/../hw/cpu.sh"          # CPU metrics
source "$_SYSTEM_DIR/../hw/memory.sh"       # Memory/swap metrics
source "$_SYSTEM_DIR/../storage/storage.sh" # Storage/disk metrics
source "$_SYSTEM_DIR/../hw/gpu.sh"          # GPU metrics
source "$_SYSTEM_DIR/../net/network.sh"     # Network interface info
