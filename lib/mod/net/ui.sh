#!/usr/bin/env bash
# network.sh - Network interface visualization functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_UI_NETWORK_LOADED:-}" ]] && return 0
_UI_NETWORK_LOADED=1

# Source dependencies
_UI_NETWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_NETWORK_DIR/../../core/term/colors.sh"
source "$_UI_NETWORK_DIR/../../ui/widgets/gauge.sh"

#---------------------------------------
# Network interface visualization
#---------------------------------------

# Network status colors
declare -A _UI_NET_STATUS_COLORS=(
    ["up"]="$NEON_GREEN"
    ["down"]="$NEON_RED"
    ["no-driver"]="$NEON_YELLOW"
    ["unknown"]="$BRIGHT_BLACK"
)

# Get color for network status
# Usage: color=$(_ui_net_status_color "up")
_ui_net_status_color() {
    local status="${1:-unknown}"
    echo "${_UI_NET_STATUS_COLORS[$status]:-$BRIGHT_BLACK}"
}

# Display network interface status with colored indicator
# Usage: ui_net_status "up" -> "● Connected" (green)
# Usage: ui_net_status "down" -> "○ Disconnected" (red)
# Usage: ui_net_status "no-driver" -> "◌ No Driver" (yellow)
ui_net_status() {
    local status="${1:-unknown}"
    local color
    color=$(_ui_net_status_color "$status")

    local icon label
    case "$status" in
    up)
        icon="●"
        label="Connected"
        ;;
    down)
        icon="○"
        label="Disconnected"
        ;;
    no-driver)
        icon="◌"
        label="No Driver"
        ;;
    *)
        icon="?"
        label="Unknown"
        ;;
    esac

    printf "%s%s %s%s" "$color" "$icon" "$label" "$RESET"
}

# Display network interface type icon
# Usage: ui_net_type_icon "ethernet" -> "🔌"
# Usage: ui_net_type_icon "wireless" -> "📶"
ui_net_type_icon() {
    local iface_type="$1"
    case "$iface_type" in
    ethernet) echo "🔌" ;;
    wireless) echo "📶" ;;
    *) echo "🌐" ;;
    esac
}

# Display a compact network interface line
# Usage: ui_net_interface_line "eth0" "ethernet" "up" "1000 Mbps" "192.168.1.100" "Intel I226"
ui_net_interface_line() {
    local iface="$1"
    local iface_type="$2"
    local state="$3"
    local speed="${4:--}"
    local ip="${5:--}"
    local model="${6:-Unknown adapter}"

    local icon status_str
    icon=$(ui_net_type_icon "$iface_type")
    status_str=$(ui_net_status "$state")

    local output=""
    output+="  ${BOLD}$icon $iface${RESET} - $status_str\n"
    output+="     ${DIM}$model${RESET}\n"

    # Show IP and speed if connected
    if [[ "$state" == "up" ]]; then
        local details=""
        [[ "$ip" != "-" ]] && details+="IP: ${NEON_CYAN}$ip${RESET}"
        if [[ "$speed" != "-" ]]; then
            [[ -n "$details" ]] && details+="  "
            details+="Speed: ${NEON_GREEN}$speed${RESET}"
        fi
        [[ -n "$details" ]] && output+="     $details\n"
    fi

    printf "%b" "$output"
}

# Display WiFi signal strength bar
# Usage: ui_wifi_signal 75 -> "████░ 75%"
ui_wifi_signal() {
    local percent="${1:-0}"
    local width="${2:-5}"

    percent=$(_ui_clamp_percent "$percent")
    local filled=$((percent * width / 100))

    local color
    if ((percent >= 70)); then
        color="$NEON_GREEN"
    elif ((percent >= 40)); then
        color="$NEON_YELLOW"
    else
        color="$NEON_RED"
    fi

    local bar
    bar=$(_ui_build_bar "$filled" $((width - filled)))
    printf "%s%s%s %d%%" "$color" "$bar" "$RESET" "$percent"
}
