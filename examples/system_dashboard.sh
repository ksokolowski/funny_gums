#!/usr/bin/env bash
# system_dashboard.sh - System information dashboard
# Demonstrates: ui_table, ui_box, ui_join, ui_spin, ui_spin_type, log_structured
# shellcheck disable=SC1091
set -u

############################
# SCRIPT CONFIGURATION
############################
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source library
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/logging.sh"

# Initialize logging
LOG_FILE="/tmp/system_dashboard.log"
log_init "$LOG_FILE"

############################
# DATA COLLECTION FUNCTIONS
############################
get_system_info() {
    local hostname kernel uptime
    hostname=$(hostname)
    kernel=$(uname -r)
    uptime=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    
    echo "Hostname,$hostname"
    echo "Kernel,$kernel"
    echo "Uptime,$uptime"
    echo "OS,$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)"
}

get_cpu_info() {
    local model cores load
    model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "?")
    load=$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | xargs)
    
    echo "Model,$model"
    echo "Cores,$cores"
    echo "Load (1/5/15m),$load"
}

get_memory_info() {
    if command -v free >/dev/null 2>&1; then
        free -h | awk 'NR==2{printf "Total,%s\nUsed,%s\nFree,%s\nUsage,%.1f%%\n", $2, $3, $4, $3/$2*100}'
    else
        # macOS fallback
        local total
        total=$(sysctl -n hw.memsize 2>/dev/null | awk '{print $1/1024/1024/1024 " GB"}')
        echo "Total,$total"
        echo "Used,N/A"
        echo "Free,N/A"
    fi
}

get_disk_info() {
    df -h / | awk 'NR==2{printf "Total,%s\nUsed,%s\nFree,%s\nUsage,%s\n", $2, $3, $4, $5}'
}

get_network_info() {
    local ip_addr gateway
    ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "Unknown")
    gateway=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -1 || route -n get default 2>/dev/null | grep gateway | awk '{print $2}' || echo "Unknown")
    
    echo "IP Address,$ip_addr"
    echo "Gateway,$gateway"
    echo "Hostname,$(hostname)"
}

get_top_processes() {
    ps aux --sort=-%cpu 2>/dev/null | head -6 | awk 'NR>1{printf "%s,%.1f%%,%.1f%%\n", $11, $3, $4}' | head -5
}

############################
# DISPLAY FUNCTIONS
############################
show_section() {
    local title="$1"
    local data="$2"
    
    echo ""
    ui_info "$title"
    echo "$data" | gum table --separator ","
}

show_dashboard() {
    clear
    
    echo ""
    ui_box_double "🖥️  System Dashboard" \
        "" \
        "Real-time system information" \
        "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Collect data with spinners
    echo ""
    system_data=$(ui_spin_type dot "Gathering system info..." bash -c "$(declare -f get_system_info); get_system_info")
    cpu_data=$(ui_spin_type dot "Gathering CPU info..." bash -c "$(declare -f get_cpu_info); get_cpu_info")
    mem_data=$(ui_spin_type dot "Gathering memory info..." bash -c "$(declare -f get_memory_info); get_memory_info")
    disk_data=$(ui_spin_type dot "Gathering disk info..." bash -c "$(declare -f get_disk_info); get_disk_info")
    net_data=$(ui_spin_type dot "Gathering network info..." bash -c "$(declare -f get_network_info); get_network_info")
    
    # Log the collection
    log_structured info "Dashboard refreshed" timestamp "$(date -Iseconds)"
    
    # Display sections
    show_section "📋 System" "$system_data"
    show_section "🧠 CPU" "$cpu_data"
    show_section "💾 Memory" "$mem_data"
    show_section "💿 Disk (/)" "$disk_data"
    show_section "🌐 Network" "$net_data"
    
    # Top processes
    echo ""
    ui_info "🔝 Top Processes (by CPU)"
    {
        echo "Command,CPU,Memory"
        get_top_processes
    } | gum table --separator ","
}

############################
# MAIN
############################
echo ""
ui_box "🖥️  System Dashboard" \
    "" \
    "This tool displays real-time system information" \
    "including CPU, memory, disk, and network stats."

echo ""
if ! ui_confirm "Show system dashboard?"; then
    ui_info "Goodbye!"
    exit 0
fi

while true; do
    show_dashboard
    
    echo ""
    action=$(ui_choose_with_header "Options:" \
        "🔄 Refresh" \
        "📊 View detailed processes" \
        "📝 View log" \
        "❌ Exit")
    
    case "$action" in
        "🔄 Refresh")
            continue
            ;;
        
        "📊 View detailed processes")
            echo ""
            ui_info "Top 20 processes by CPU usage:"
            {
                echo "USER,PID,CPU%,MEM%,COMMAND"
                ps aux --sort=-%cpu 2>/dev/null | head -21 | awk 'NR>1{printf "%s,%s,%.1f,%.1f,%s\n", $1, $2, $3, $4, $11}'
            } | gum table --separator ","
            echo ""
            read -r -p "Press Enter to continue..."
            ;;
        
        "📝 View log")
            log_show
            ;;
        
        "❌ Exit"|"")
            ui_info "Goodbye!"
            log_structured info "Dashboard closed" session_duration "$(ps -o etime= -p $$)"
            exit 0
            ;;
    esac
done
