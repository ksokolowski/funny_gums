#!/usr/bin/env bash
# gpu.sh - GPU monitoring functions
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_GPU_LOADED:-}" ]] && return 0
_SYSTEM_GPU_LOADED=1

# Get GPU temperature (NVIDIA or AMD)
# Usage: gpu_temp=$(get_gpu_temp_live)
get_gpu_temp_live() {
    local temp

    # Try nvidia-smi
    if command -v nvidia-smi &>/dev/null; then
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
        [[ -n "$temp" ]] && { echo "$temp"; return; }
    fi

    # Try AMD via sensors
    if command -v sensors &>/dev/null; then
        temp=$(sensors 2>/dev/null | grep -E "(edge|junction)" | head -1 | grep -oP '\+\K[0-9]+(?=\.[0-9]*°C)')
        [[ -n "$temp" ]] && { echo "$temp"; return; }
    fi

    echo ""
}
