#!/usr/bin/env bash
# network.sh - Network interface monitoring functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_NETWORK_LOADED:-}" ]] && return 0
_SYSTEM_NETWORK_LOADED=1

# Source lspci module for PCI device queries
_SYSTEM_NETWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SYSTEM_NETWORK_DIR/../os/lspci.sh"

# Get physical network interfaces with status
# Usage: get_network_interfaces
# Returns lines: "interface|type|state|speed|mac|ip|driver|model"
# type: ethernet, wireless
# state: up, down, no-driver
get_network_interfaces() {
    # Get all physical interfaces (excluding lo, docker, veth, bridges, etc.)
    local interfaces
    interfaces=$(ip -o link show 2>/dev/null |
        grep -vE "lo:|docker|veth|br-|virbr|tun|tap" |
        awk -F': ' '{print $2}' | cut -d'@' -f1)

    for iface in $interfaces; do
        [[ -z "$iface" ]] && continue

        local iface_type="ethernet"
        local state="down"
        local speed="-"
        local mac="-"
        local ip_addr="-"
        local driver="-"
        local model="-"

        # Check if wireless
        if [[ -d "/sys/class/net/$iface/wireless" ]]; then
            iface_type="wireless"
        fi

        # Get MAC address
        mac=$(ip -o link show "$iface" 2>/dev/null |
            grep -oE "link/ether [0-9a-f:]+" | awk '{print $2}')
        [[ -z "$mac" ]] && mac="-"

        # Get state from ip link
        local link_info
        link_info=$(ip -o link show "$iface" 2>/dev/null)
        if [[ "$link_info" == *"state UP"* ]]; then
            state="up"
        elif [[ "$link_info" == *"NO-CARRIER"* ]]; then
            state="down"
        elif [[ "$link_info" == *"state DOWN"* ]]; then
            state="down"
        fi

        # Get IP address if connected
        ip_addr=$(ip -o -4 addr show "$iface" 2>/dev/null |
            awk '{print $4}' | cut -d'/' -f1 | head -1)
        [[ -z "$ip_addr" ]] && ip_addr="-"

        # Get speed (only works for ethernet when connected)
        if [[ "$state" == "up" ]] && [[ -f "/sys/class/net/$iface/speed" ]]; then
            speed=$(cat "/sys/class/net/$iface/speed" 2>/dev/null)
            [[ "$speed" == "-1" ]] && speed="-"
            [[ -n "$speed" ]] && [[ "$speed" != "-" ]] && speed="${speed} Mbps"
        fi

        # Get driver name
        if [[ -L "/sys/class/net/$iface/device/driver" ]]; then
            driver=$(basename "$(readlink -f "/sys/class/net/$iface/device/driver")" 2>/dev/null)
        fi
        [[ -z "$driver" ]] && driver="-"

        # Try to get model from lspci via lspci module
        local pci_path
        pci_path=$(readlink -f "/sys/class/net/$iface/device" 2>/dev/null)
        if [[ -n "$pci_path" ]] && [[ -f "$pci_path/vendor" ]]; then
            local pci_id
            pci_id=$(basename "$pci_path" 2>/dev/null)
            if [[ "$pci_id" =~ ^[0-9a-f]{4}: ]] && lspci_available; then
                model=$(lspci_get_device_name "$pci_id")
            fi
        fi
        # Fallback: use driver name as model
        [[ -z "$model" ]] || [[ "$model" == "-" ]] && model="$driver adapter"

        # Check for no-driver situation
        if [[ "$driver" == "-" ]] || [[ "$driver" == "N/A" ]]; then
            state="no-driver"
        fi

        echo "$iface|$iface_type|$state|$speed|$mac|$ip_addr|$driver|$model"
    done
}

# Get wireless signal strength
# Usage: get_wifi_signal "wlan0"
# Returns: Signal strength percentage or empty
get_wifi_signal() {
    local iface="$1"
    local signal=""

    if [[ -d "/sys/class/net/$iface/wireless" ]]; then
        # Try iwconfig
        if command -v iwconfig &>/dev/null; then
            local quality
            quality=$(iwconfig "$iface" 2>/dev/null | grep -oE "Link Quality=[0-9]+/[0-9]+" | cut -d'=' -f2)
            if [[ -n "$quality" ]]; then
                local num den
                num="${quality%/*}"
                den="${quality#*/}"
                [[ "$den" -gt 0 ]] && signal=$((num * 100 / den))
            fi
        fi

        # Fallback: try /proc/net/wireless
        if [[ -z "$signal" ]] && [[ -f /proc/net/wireless ]]; then
            local level
            level=$(grep "$iface" /proc/net/wireless 2>/dev/null | awk '{print $3}' | tr -d '.')
            [[ -n "$level" ]] && signal=$((level + 110)) # Convert dBm to rough percentage
            [[ "$signal" -gt 100 ]] && signal=100
            [[ "$signal" -lt 0 ]] && signal=0
        fi
    fi

    echo "$signal"
}
