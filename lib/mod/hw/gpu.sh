#!/usr/bin/env bash
# gpu.sh - GPU monitoring functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_GPU_LOADED:-}" ]] && return 0
_SYSTEM_GPU_LOADED=1

# Source NVIDIA and AMD modules for GPU queries
_SYSTEM_GPU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SYSTEM_GPU_DIR/nvidia.sh"
source "$_SYSTEM_GPU_DIR/amd.sh"

# Get GPU temperature (NVIDIA or AMD)
# Usage: gpu_temp=$(get_gpu_temp_live)
get_gpu_temp_live() {
    local temp

    # Try NVIDIA via nvidia module
    if nvidia_available; then
        temp=$(nvidia_get_temp)
        [[ -n "$temp" ]] && {
            echo "$temp"
            return
        }
    fi

    # Try AMD via amd module
    temp=$(amd_get_temp)
    [[ -n "$temp" ]] && {
        echo "$temp"
        return
    }

    echo ""
}
