#!/usr/bin/env bash
# lspci.sh - PCI device query abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_LSPCI_LOADED:-}" ]] && return 0
_SYSTEM_LSPCI_LOADED=1

# Check if lspci is installed
# Usage: lspci_available && echo "lspci installed"
lspci_available() {
    command -v lspci &>/dev/null
}

# Get device name by PCI slot ID
# Usage: name=$(lspci_get_device_name "00:1f.6")
# Returns: Device name string or empty
lspci_get_device_name() {
    local pci_id="$1"
    lspci_available || return 1
    [[ -z "$pci_id" ]] && return 1
    lspci -s "$pci_id" 2>/dev/null | sed 's/.*: //' | head -1
}

# Get network devices (Ethernet controllers)
# Usage: lspci_get_network_devices
# Returns: Lines of "pci_id|vendor|device|driver"
lspci_get_network_devices() {
    lspci_available || return 1
    lspci -Dnn 2>/dev/null | grep -E "(Ethernet|Network)" | while IFS= read -r line; do
        # Parse: 0000:00:1f.6 Ethernet controller: Intel Corporation ...
        local pci_id vendor_device
        pci_id=$(echo "$line" | awk '{print $1}')
        vendor_device=$(echo "$line" | sed 's/^[^ ]* [^:]*: //')

        # Try to get driver
        local driver="-"
        if [[ -n "$pci_id" ]]; then
            driver=$(lspci -s "$pci_id" -k 2>/dev/null | grep "Kernel driver" | awk '{print $NF}')
            [[ -z "$driver" ]] && driver="-"
        fi

        echo "${pci_id}|${vendor_device}|${driver}"
    done
}

# Get GPU devices (VGA and 3D controllers)
# Usage: lspci_get_gpu_devices
# Returns: Lines of "pci_id|vendor|device|driver"
lspci_get_gpu_devices() {
    lspci_available || return 1
    lspci -Dnn 2>/dev/null | grep -E "(VGA|3D|Display)" | while IFS= read -r line; do
        local pci_id vendor_device
        pci_id=$(echo "$line" | awk '{print $1}')
        vendor_device=$(echo "$line" | sed 's/^[^ ]* [^:]*: //')

        # Try to get driver
        local driver="-"
        if [[ -n "$pci_id" ]]; then
            driver=$(lspci -s "$pci_id" -k 2>/dev/null | grep "Kernel driver" | awk '{print $NF}')
            [[ -z "$driver" ]] && driver="-"
        fi

        echo "${pci_id}|${vendor_device}|${driver}"
    done
}

# Get all PCI devices with optional class filter
# Usage: lspci_get_devices "VGA"
# Returns: Lines of "pci_id|class|vendor_device"
lspci_get_devices() {
    local filter="${1:-}"
    lspci_available || return 1

    local cmd_output
    if [[ -n "$filter" ]]; then
        cmd_output=$(lspci -Dnn 2>/dev/null | grep -F "$filter")
    else
        cmd_output=$(lspci -Dnn 2>/dev/null)
    fi

    echo "$cmd_output" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local pci_id class_type vendor_device
        pci_id=$(echo "$line" | awk '{print $1}')
        # Extract class type (second field before colon)
        class_type=$(echo "$line" | sed 's/^[^ ]* \([^:]*\):.*/\1/')
        vendor_device=$(echo "$line" | sed 's/^[^ ]* [^:]*: //')
        echo "${pci_id}|${class_type}|${vendor_device}"
    done
}
