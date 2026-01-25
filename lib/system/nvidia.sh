#!/usr/bin/env bash
# nvidia.sh - NVIDIA GPU query abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_NVIDIA_LOADED:-}" ]] && return 0
_SYSTEM_NVIDIA_LOADED=1

# Check if nvidia-smi is installed
# Usage: nvidia_available && echo "nvidia-smi installed"
nvidia_available() {
    command -v nvidia-smi &>/dev/null
}

# Get GPU temperature
# Usage: temp=$(nvidia_get_temp)
# Returns: Temperature in Celsius (integer) or empty
nvidia_get_temp() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1
}

# Get GPU utilization percentage
# Usage: util=$(nvidia_get_utilization)
# Returns: Utilization percentage (0-100) or empty
nvidia_get_utilization() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1
}

# Get GPU memory usage
# Usage: read -r used total <<< "$(nvidia_get_memory_usage)"
# Returns: "used_mib total_mib" or empty
nvidia_get_memory_usage() {
    nvidia_available || return 1
    local used total
    used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1)
    total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    [[ -n "$used" ]] && [[ -n "$total" ]] && echo "$used $total"
}

# Get GPU power draw in watts
# Usage: power=$(nvidia_get_power_draw)
# Returns: Power in watts (float) or empty
nvidia_get_power_draw() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1
}

# Get GPU fan speed percentage
# Usage: fan=$(nvidia_get_fan_speed)
# Returns: Fan speed percentage or empty
nvidia_get_fan_speed() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null | head -1
}

# Get GPU model name
# Usage: name=$(nvidia_get_gpu_name)
# Returns: GPU model name or empty
nvidia_get_gpu_name() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1
}

# Get GPU clock speeds
# Usage: read -r graphics memory <<< "$(nvidia_get_clocks)"
# Returns: "graphics_mhz memory_mhz" or empty
nvidia_get_clocks() {
    nvidia_available || return 1
    local graphics memory
    graphics=$(nvidia-smi --query-gpu=clocks.current.graphics --format=csv,noheader,nounits 2>/dev/null | head -1)
    memory=$(nvidia-smi --query-gpu=clocks.current.memory --format=csv,noheader,nounits 2>/dev/null | head -1)
    [[ -n "$graphics" ]] && [[ -n "$memory" ]] && echo "$graphics $memory"
}

# Get GPU driver version
# Usage: version=$(nvidia_get_driver_version)
nvidia_get_driver_version() {
    nvidia_available || return 1
    nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1
}
