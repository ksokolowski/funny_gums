#!/usr/bin/env bash
# system_dashboard.sh - AIDA64/HWiNFO-style system information dashboard
# Demonstrates: sidebar layout, progress bars, color-coded temps, auto-refresh
# shellcheck disable=SC1091,SC2034
set -u

################################################################################
# CONFIGURATION
################################################################################
REFRESH_INTERVAL=5           # Sensor refresh interval in seconds
MIN_COLS=100                 # Minimum terminal width required
MIN_ROWS=30                  # Minimum terminal height required
NAV_PANEL_WIDTH=22           # Width of left navigation panel
INXI_GITHUB="https://github.com/smxi/inxi"

# Threshold configuration (centralized for easy tuning)
RESOURCE_WARN=70             # Warning threshold for CPU/RAM/Disk (%)
RESOURCE_CRIT=90             # Critical threshold for CPU/RAM/Disk (%)
SWAP_WARN=50                 # Warning threshold for swap (%)
SWAP_CRIT=80                 # Critical threshold for swap (%)
TEMP_WARN=70                 # Warning threshold for temps (°C)
TEMP_CRIT=85                 # Critical threshold for temps (°C)

################################################################################
# PATH RESOLUTION (supports symlinks)
################################################################################
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

################################################################################
# SOURCE LIBRARIES
################################################################################
source "$LIB_DIR/core/colors.sh"
source "$LIB_DIR/core/cursor.sh"
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/ui/ui.sh"
source "$LIB_DIR/system/system.sh"

################################################################################
# STATE VARIABLES
################################################################################
CURRENT_CATEGORY=0           # Currently selected category index (0-7)
VIEW_MODE="overview"         # "overview" or "detail"
AUTO_REFRESH=true            # Toggle with 'A' key
INXI_CACHE=""                # Cached inxi output
TERM_COLS=0                  # Terminal columns
TERM_ROWS=0                  # Terminal rows
LAST_SENSOR_UPDATE=""        # Timestamp of last sensor update

# Live metrics cache (updated on refresh)
LIVE_CPU_PERCENT=0
LIVE_MEM_USED_KB=0
LIVE_MEM_TOTAL_KB=0
LIVE_MEM_PERCENT=0
LIVE_SWAP_USED_KB=0
LIVE_SWAP_TOTAL_KB=0
LIVE_SWAP_PERCENT=0
LIVE_DISK_PERCENT=0
LIVE_DISK_USED=""
LIVE_DISK_TOTAL=""
LIVE_CPU_TEMP=""
LIVE_GPU_TEMP=""
LIVE_CPU_FREQ=""

# Pre-formatted human-readable values (cached to avoid repeated formatting)
LIVE_MEM_USED_HR=""
LIVE_MEM_TOTAL_HR=""
LIVE_SWAP_USED_HR=""
LIVE_SWAP_TOTAL_HR=""

# Calculated dimensions (set once at startup)
PANEL_WIDTH=0

# Category definitions: name, icon, inxi_section
declare -a CATEGORIES=(
    "System|📋|System"
    "CPU|🧠|CPU"
    "Memory|💾|Memory"
    "Storage|💿|Drives"
    "Graphics|🎮|Graphics"
    "Audio|🔊|Audio"
    "Network|🌐|Network"
    "Sensors|🌡️|Sensors"
)

################################################################################
# DEPENDENCY CHECKS
################################################################################
check_dependencies() {
    if ! command -v inxi &>/dev/null; then
        echo ""
        gum style --foreground 196 --bold "ERROR: inxi is required but not installed"
        echo ""
        gum style --foreground 245 "Install inxi from your package manager or visit:"
        gum style --foreground 39 --underline "$INXI_GITHUB"
        echo ""
        gum style --foreground 245 "Example installation:"
        gum style --foreground 255 "  Ubuntu/Debian: sudo apt install inxi"
        gum style --foreground 255 "  Fedora:        sudo dnf install inxi"
        gum style --foreground 255 "  Arch:          sudo pacman -S inxi"
        echo ""
        exit 1
    fi

    if ! command -v gum &>/dev/null; then
        echo "ERROR: gum is required but not installed"
        echo "Visit: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

check_terminal_size() {
    TERM_COLS=$(tput cols)
    TERM_ROWS=$(tput lines)

    if [[ $TERM_COLS -lt $MIN_COLS ]] || [[ $TERM_ROWS -lt $MIN_ROWS ]]; then
        echo ""
        gum style --foreground 214 --bold "Terminal too small: ${TERM_COLS}x${TERM_ROWS}"
        echo ""
        gum style --foreground 245 "This dashboard requires at least ${MIN_COLS}x${MIN_ROWS}."
        gum style --foreground 245 "Please resize your terminal or use inxi directly:"
        echo ""
        gum style --foreground 39 "  inxi -Fxxxz"
        echo ""
        exit 1
    fi
}

################################################################################
# DATA COLLECTION
################################################################################
refresh_inxi_data() {
    INXI_CACHE=$(inxi -Fxz -c0 2>/dev/null)
}

refresh_live_metrics() {
    # CPU usage (this takes ~100ms due to sampling)
    LIVE_CPU_PERCENT=$(get_cpu_usage_live)

    # Memory (raw + pre-formatted)
    read -r LIVE_MEM_USED_KB LIVE_MEM_TOTAL_KB LIVE_MEM_PERCENT <<< "$(get_memory_usage_live)"
    LIVE_MEM_USED_HR=$(format_kb "$LIVE_MEM_USED_KB")
    LIVE_MEM_TOTAL_HR=$(format_kb "$LIVE_MEM_TOTAL_KB")

    # Swap (raw + pre-formatted)
    read -r LIVE_SWAP_USED_KB LIVE_SWAP_TOTAL_KB LIVE_SWAP_PERCENT <<< "$(get_swap_usage_live)"
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        LIVE_SWAP_USED_HR=$(format_kb "$LIVE_SWAP_USED_KB")
        LIVE_SWAP_TOTAL_HR=$(format_kb "$LIVE_SWAP_TOTAL_KB")
    else
        LIVE_SWAP_USED_HR=""
        LIVE_SWAP_TOTAL_HR=""
    fi

    # Root disk
    local disk_used disk_total
    read -r disk_used disk_total LIVE_DISK_PERCENT <<< "$(get_root_disk_usage_live)"
    LIVE_DISK_USED=$(format_bytes "$disk_used")
    LIVE_DISK_TOTAL=$(format_bytes "$disk_total")

    # Temperatures
    LIVE_CPU_TEMP=$(get_cpu_temp_live)
    LIVE_GPU_TEMP=$(get_gpu_temp_live)

    # CPU frequency
    LIVE_CPU_FREQ=$(get_cpu_freq_live)

    LAST_SENSOR_UPDATE=$(date '+%H:%M:%S')
}

################################################################################
# CATEGORY CONTENT BUILDERS
################################################################################
get_category_content() {
    local cat_idx="$1"
    local cat_def="${CATEGORIES[$cat_idx]}"
    local cat_name cat_icon cat_section
    IFS='|' read -r cat_name cat_icon cat_section <<< "$cat_def"

    case "$cat_section" in
        "System")   inxi_parse_system_csv ;;
        "CPU")      inxi_parse_cpu_csv ;;
        "Memory")   inxi_parse_memory_csv ;;
        "Drives")
            echo "Item,Value"
            inxi_get_section "Drives" | sed '1d' | sed 's/^[[:space:]]*//' | while read -r line; do
                [[ -n "$line" ]] && echo "$line" | sed 's/: /,/' | head -1
            done
            echo ""
            echo "Partitions:"
            inxi_parse_partition_csv
            ;;
        "Graphics") inxi_parse_graphics_csv ;;
        "Audio")    inxi_parse_audio_csv ;;
        "Network")  inxi_parse_network_csv ;;
        "Sensors")  inxi_parse_sensors_csv ;;
        *)
            echo "Item,Value"
            echo "Info,No data available"
            ;;
    esac
}

################################################################################
# UI BUILDING FUNCTIONS
################################################################################
build_header() {
    local title="🖥️  System Dashboard"
    local timestamp
    timestamp=$(date '+%H:%M:%S')

    local mode_indicator
    if [[ "$VIEW_MODE" == "overview" ]]; then
        mode_indicator="Overview"
    else
        local cat_def="${CATEGORIES[$CURRENT_CATEGORY]}"
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"
        mode_indicator="$cat_icon $cat_name"
    fi

    local auto_status
    if [[ "$AUTO_REFRESH" == true ]]; then
        auto_status="${NEON_GREEN}[Auto: ON]${RESET}"
    else
        auto_status="${BRIGHT_BLACK}[Auto: OFF]${RESET}"
    fi

    local header_width=$((TERM_COLS - 4))
    local header_text="$title │ $mode_indicator │ $timestamp  $auto_status"

    gum style --border double --border-foreground 39 --width "$header_width" \
        --padding "0 1" "$header_text"
}

build_nav_panel() {
    local lines=""
    local i=0

    lines+="  ${BOLD}Categories${RESET}\n"
    lines+="  ──────────────\n"

    for cat_def in "${CATEGORIES[@]}"; do
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"

        if [[ $i -eq $CURRENT_CATEGORY ]]; then
            lines+="  ${NEON_CYAN}▶ $cat_icon $cat_name${RESET}\n"
        else
            lines+="    $cat_icon $cat_name\n"
        fi
        ((i++))
    done

    lines+="\n"
    lines+="  ─────────────\n"
    lines+="  ${DIM}Quick Stats${RESET}\n"

    # Mini gauges in sidebar (using centralized thresholds)
    local cpu_bar mem_bar disk_bar
    cpu_bar=$(ui_minibar_colored "$LIVE_CPU_PERCENT" 5 "$RESOURCE_WARN" "$RESOURCE_CRIT")
    mem_bar=$(ui_minibar_colored "$LIVE_MEM_PERCENT" 5 "$RESOURCE_WARN" "$RESOURCE_CRIT")
    disk_bar=$(ui_minibar_colored "$LIVE_DISK_PERCENT" 5 "$RESOURCE_WARN" "$RESOURCE_CRIT")

    lines+="  CPU:  ${LIVE_CPU_PERCENT}%  $cpu_bar\n"
    lines+="  RAM:  ${LIVE_MEM_PERCENT}%  $mem_bar\n"
    lines+="  Disk: ${LIVE_DISK_PERCENT}%  $disk_bar\n"

    echo -e "$lines" | gum style --no-strip-ansi --border rounded --border-foreground 240 \
        --width "$NAV_PANEL_WIDTH" --height 20 --padding "0 1"
}

build_system_panel() {
    local content=""

    content+="${BOLD}System Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # Get system info
    local host os kernel desktop uptime_str
    host=$(hostname 2>/dev/null || echo "Unknown")
    os=$(grep -E "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
    kernel=$(uname -r 2>/dev/null || echo "Unknown")
    desktop="${XDG_CURRENT_DESKTOP:-Unknown}"
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

    content+="  Host:      $host\n"
    content+="  OS:        $os\n"
    content+="  Kernel:    $kernel\n"
    content+="  Desktop:   $desktop\n"
    content+="  Uptime:    $uptime_str\n\n"

    content+="${BOLD}Resource Usage${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # CPU gauge with frequency
    local cpu_gauge freq_str=""
    cpu_gauge=$(ui_gauge_colored "$LIVE_CPU_PERCENT" 100 25 "CPU" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    [[ -n "$LIVE_CPU_FREQ" ]] && freq_str="  ${LIVE_CPU_FREQ} MHz"
    content+="  $cpu_gauge$freq_str\n\n"

    # Memory gauge (using cached formatted values)
    local mem_gauge
    mem_gauge=$(ui_gauge_colored "$LIVE_MEM_PERCENT" 100 25 "RAM" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $mem_gauge  $LIVE_MEM_USED_HR / $LIVE_MEM_TOTAL_HR\n\n"

    # Disk gauge
    local disk_gauge
    disk_gauge=$(ui_gauge_colored "$LIVE_DISK_PERCENT" 100 25 "Disk" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $disk_gauge  $LIVE_DISK_USED / $LIVE_DISK_TOTAL\n\n"

    # Swap gauge (using cached formatted values)
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        local swap_gauge
        swap_gauge=$(ui_gauge_colored "$LIVE_SWAP_PERCENT" 100 25 "Swap" "$SWAP_WARN" "$SWAP_CRIT")
        content+="  $swap_gauge  $LIVE_SWAP_USED_HR / $LIVE_SWAP_TOTAL_HR\n"
    else
        content+="  ${DIM}Swap:    Not configured${RESET}\n"
    fi

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_cpu_panel() {
    local content=""

    content+="${BOLD}CPU Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # Get CPU model from inxi cache
    local cpu_model
    cpu_model=$(echo "$INXI_CACHE" | grep -A5 "^CPU:" | grep "model:" | sed 's/.*model: //' | cut -d' ' -f1-6)
    [[ -z "$cpu_model" ]] && cpu_model=$(lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:[[:space:]]*//')

    content+="  Model:     $cpu_model\n\n"

    # CPU usage gauge
    local cpu_gauge
    cpu_gauge=$(ui_gauge_colored "$LIVE_CPU_PERCENT" 100 30 "Usage" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $cpu_gauge\n\n"

    # Temperature gauge (if available)
    if [[ -n "$LIVE_CPU_TEMP" ]]; then
        local temp_display
        temp_display=$(ui_temp_gauge "$LIVE_CPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "Temp")
        content+="  $temp_display\n\n"
    fi

    # Frequency
    if [[ -n "$LIVE_CPU_FREQ" ]]; then
        content+="  Frequency: ${LIVE_CPU_FREQ} MHz\n\n"
    fi

    # Load average
    local load_avg
    load_avg=$(get_load_avg_live)
    content+="  Load Avg:  $load_avg\n\n"

    # Additional CPU info from inxi
    content+="${BOLD}Details${RESET}\n"
    content+="────────────────────────────────────────\n"
    local cpu_details
    cpu_details=$(get_category_content 1 | tail -n +2 | head -10 | \
        awk -F',' '{if(NF>=2) printf "  %-12s %s\n", $1":", $2}')
    content+="$cpu_details"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_memory_panel() {
    local content=""

    content+="${BOLD}Memory Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # RAM usage (using cached formatted values)
    local mem_gauge
    mem_gauge=$(ui_gauge_colored "$LIVE_MEM_PERCENT" 100 30 "RAM" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $mem_gauge\n"
    content+="  Used: $LIVE_MEM_USED_HR / Total: $LIVE_MEM_TOTAL_HR\n\n"

    # Swap usage (using cached formatted values)
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        local swap_gauge
        swap_gauge=$(ui_gauge_colored "$LIVE_SWAP_PERCENT" 100 30 "Swap" "$SWAP_WARN" "$SWAP_CRIT")
        content+="  $swap_gauge\n"
        content+="  Used: $LIVE_SWAP_USED_HR / Total: $LIVE_SWAP_TOTAL_HR\n\n"
    else
        content+="  ${DIM}Swap: Not configured${RESET}\n\n"
    fi

    # Buffers/cache info
    local buffers cached
    buffers=$(awk '/^Buffers:/ {printf "%.1f MiB", $2/1024}' /proc/meminfo 2>/dev/null)
    cached=$(awk '/^Cached:/ {printf "%.1f MiB", $2/1024}' /proc/meminfo 2>/dev/null)
    content+="  Buffers:   $buffers\n"
    content+="  Cached:    $cached\n\n"

    # Additional memory info from inxi
    content+="${BOLD}Details${RESET}\n"
    content+="────────────────────────────────────────\n"
    local mem_details
    mem_details=$(get_category_content 2 | tail -n +2 | head -10 | \
        awk -F',' '{if(NF>=2) printf "  %-12s %s\n", $1":", $2}')
    content+="$mem_details"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_storage_panel() {
    local content=""
    local bar_width=35

    content+="${BOLD}Storage - Physical Drives${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # Iterate through physical drives
    while IFS='|' read -r drive_name size_bytes model drive_type; do
        [[ -z "$drive_name" ]] && continue

        local size_hr icon
        size_hr=$(format_bytes "$size_bytes")

        case "$drive_type" in
            nvme) icon="⚡" ;;
            ssd)  icon="💾" ;;
            hdd)  icon="💿" ;;
            *)    icon="📀" ;;
        esac

        # Drive header
        content+="  ${BOLD}$icon $model${RESET} ${DIM}($size_hr - ${drive_type^^})${RESET}\n"

        # Collect partitions
        local partitions=()
        local part_lines=""

        while IFS='|' read -r part_name part_size part_fs part_mount part_used; do
            [[ -z "$part_name" ]] && continue

            # Get color for filesystem
            local color
            color=$(_ui_fstype_color "$part_fs")

            partitions+=("$part_size|$color")

            # Format partition info
            local part_size_hr
            part_size_hr=$(format_bytes "$part_size")

            local mount_str=""
            [[ "$part_mount" != "-" ]] && mount_str=" → $part_mount"

            local used_str=""
            if [[ "$part_used" -gt 0 ]] && [[ "$part_size" -gt 0 ]]; then
                local used_pct=$((part_used * 100 / part_size))
                local used_hr
                used_hr=$(format_bytes "$part_used")
                used_str=" ${DIM}[${used_hr}, ${used_pct}%]${RESET}"
            fi

            part_lines+="     ${color}█${RESET} $part_name: $part_fs $part_size_hr$mount_str$used_str\n"
        done < <(get_drive_partitions "$drive_name")

        # Build partition bar
        content+="     ["
        if [[ ${#partitions[@]} -gt 0 ]]; then
            content+=$(ui_partition_bar "$size_bytes" "$bar_width" "${partitions[@]}")
        else
            # No partitions - show empty
            local i
            for ((i=0; i<bar_width; i++)); do content+="${DIM}░${RESET}"; done
        fi
        content+="]\n"

        # Add partition details
        content+="$part_lines"
        content+="\n"

    done < <(get_physical_drives)

    # Legend
    content+="${BOLD}Legend:${RESET} "
    content+=$(ui_fs_legend)

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_graphics_panel() {
    local content=""

    content+="${BOLD}Graphics Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # GPU temperature (if available)
    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        local gpu_temp_display
        gpu_temp_display=$(ui_temp_gauge "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "GPU Temp")
        content+="  $gpu_temp_display\n\n"
    fi

    # Graphics info from inxi
    content+="${BOLD}Details${RESET}\n"
    content+="────────────────────────────────────────\n"
    local gfx_details
    gfx_details=$(get_category_content 4 | tail -n +2 | head -15 | \
        awk -F',' '{if(NF>=2) printf "  %-12s %s\n", $1":", $2}')
    content+="$gfx_details"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_audio_panel() {
    local content=""

    content+="${BOLD}Audio Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # Audio info from inxi
    local audio_details
    audio_details=$(get_category_content 5 | tail -n +2 | head -15 | \
        awk -F',' '{if(NF>=2) printf "  %-12s %s\n", $1":", $2}')
    content+="$audio_details"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_network_panel() {
    local content=""

    content+="${BOLD}Network - Physical Adapters${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    local has_interfaces=false

    # Iterate through physical network interfaces
    while IFS='|' read -r iface iface_type state speed mac ip_addr driver model; do
        [[ -z "$iface" ]] && continue
        has_interfaces=true

        local icon status_color status_icon status_label
        case "$iface_type" in
            wireless) icon="📶" ;;
            ethernet) icon="🔌" ;;
            *)        icon="🌐" ;;
        esac

        status_color=$(_ui_net_status_color "$state")
        case "$state" in
            up)        status_icon="●"; status_label="Connected" ;;
            down)      status_icon="○"; status_label="Disconnected" ;;
            no-driver) status_icon="◌"; status_label="No Driver" ;;
            *)         status_icon="?"; status_label="Unknown" ;;
        esac

        # Interface header
        content+="  ${BOLD}$icon $iface${RESET} - ${status_color}${status_icon} ${status_label}${RESET}\n"

        # Model/description (truncate to fit panel width)
        if [[ "$model" != "-" ]]; then
            local max_model_len=$((PANEL_WIDTH - 12))  # Account for padding/border
            [[ ${#model} -gt $max_model_len ]] && model="${model:0:$((max_model_len-3))}..."
            content+="     ${DIM}$model${RESET}\n"
        fi

        # Connection details if up
        if [[ "$state" == "up" ]]; then
            local details=""
            if [[ "$ip_addr" != "-" ]]; then
                details+="IP: ${NEON_CYAN}$ip_addr${RESET}"
            fi
            if [[ "$speed" != "-" ]]; then
                [[ -n "$details" ]] && details+="  │  "
                details+="Speed: ${NEON_GREEN}$speed${RESET}"
            fi
            [[ -n "$details" ]] && content+="     $details\n"

            # WiFi signal strength
            if [[ "$iface_type" == "wireless" ]]; then
                local signal
                signal=$(get_wifi_signal "$iface")
                if [[ -n "$signal" ]]; then
                    local signal_bar
                    signal_bar=$(ui_wifi_signal "$signal" 5)
                    content+="     Signal: $signal_bar\n"
                fi
            fi
        fi

        # MAC address (dimmed)
        [[ "$mac" != "-" ]] && content+="     ${DIM}MAC: $mac${RESET}\n"

        # Driver info
        [[ "$driver" != "-" ]] && content+="     ${DIM}Driver: $driver${RESET}\n"

        content+="\n"
    done < <(get_network_interfaces)

    # Fallback if no interfaces found
    if ! $has_interfaces; then
        content+="  ${DIM}No physical network adapters found${RESET}\n"
    fi

    # Legend
    content+="${BOLD}Status:${RESET} "
    content+="${NEON_GREEN}● Connected${RESET}  "
    content+="${NEON_RED}○ Disconnected${RESET}  "
    content+="${NEON_YELLOW}◌ No Driver${RESET}"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_sensors_panel() {
    local content=""

    content+="${BOLD}Sensors Information${RESET}\n"
    content+="────────────────────────────────────────\n\n"

    # CPU temperature
    if [[ -n "$LIVE_CPU_TEMP" ]]; then
        local cpu_temp_display
        cpu_temp_display=$(ui_temp_gauge "$LIVE_CPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "CPU")
        content+="  $cpu_temp_display\n"
    fi

    # GPU temperature
    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        local gpu_temp_display
        gpu_temp_display=$(ui_temp_gauge "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "GPU")
        content+="  $gpu_temp_display\n"
    fi

    content+="\n"

    # Sensor info from inxi
    content+="${BOLD}All Sensors${RESET}\n"
    content+="────────────────────────────────────────\n"
    local sensor_details
    sensor_details=$(get_category_content 7 | tail -n +2 | head -15 | \
        awk -F',' '{if(NF>=2) printf "  %-12s %s\n", $1":", $2}')
    content+="$sensor_details"

    echo -e "$content" | gum style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_main_panel() {
    case "$CURRENT_CATEGORY" in
        0) build_system_panel ;;
        1) build_cpu_panel ;;
        2) build_memory_panel ;;
        3) build_storage_panel ;;
        4) build_graphics_panel ;;
        5) build_audio_panel ;;
        6) build_network_panel ;;
        7) build_sensors_panel ;;
        *) build_system_panel ;;
    esac
}

build_sensor_bar() {
    local sensor_str=""

    # CPU temperature with color (using shared helper)
    if [[ -n "$LIVE_CPU_TEMP" ]]; then
        local cpu_color
        cpu_color=$(_ui_threshold_color "$LIVE_CPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT")
        sensor_str+="${cpu_color}CPU: ${LIVE_CPU_TEMP}°C${RESET}"
    fi

    # GPU temperature with color (using shared helper)
    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        local gpu_color
        gpu_color=$(_ui_threshold_color "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT")
        [[ -n "$sensor_str" ]] && sensor_str+=" │ "
        sensor_str+="${gpu_color}GPU: ${LIVE_GPU_TEMP}°C${RESET}"
    fi

    # CPU frequency
    if [[ -n "$LIVE_CPU_FREQ" ]]; then
        [[ -n "$sensor_str" ]] && sensor_str+=" │ "
        sensor_str+="Freq: ${LIVE_CPU_FREQ} MHz"
    fi

    # Fallback
    [[ -z "$sensor_str" ]] && sensor_str="Sensors: N/A"

    # Add timestamp
    sensor_str+=" │ Updated: $LAST_SENSOR_UPDATE"

    printf "\e[48;5;236m\e[38;5;245m 🌡️  %b \e[0m" "$sensor_str"
}

build_footer() {
    local help_text="↑↓/jk Navigate │ 1-8 Jump │ A: Auto-refresh │ R: Refresh │ L: Log │ Q: Quit"
    gum style --foreground 245 --align center "$help_text"
}

################################################################################
# LAYOUT COMPOSER
################################################################################
compose_layout() {
    clear

    # Header
    build_header
    echo ""

    # Main content area - side by side
    local nav_panel main_panel
    nav_panel=$(build_nav_panel)
    main_panel=$(build_main_panel)

    # Join nav and content horizontally
    gum join --horizontal "$nav_panel" " " "$main_panel"

    echo ""

    # Sensor bar
    build_sensor_bar
    echo ""

    # Footer
    build_footer
}

################################################################################
# NAVIGATION
################################################################################
nav_up() {
    ((CURRENT_CATEGORY--))
    [[ $CURRENT_CATEGORY -lt 0 ]] && CURRENT_CATEGORY=$((${#CATEGORIES[@]} - 1))
}

nav_down() {
    ((CURRENT_CATEGORY++))
    [[ $CURRENT_CATEGORY -ge ${#CATEGORIES[@]} ]] && CURRENT_CATEGORY=0
}

jump_to_category() {
    local idx="$1"
    if [[ $idx -ge 0 ]] && [[ $idx -lt ${#CATEGORIES[@]} ]]; then
        CURRENT_CATEGORY=$idx
    fi
}

toggle_auto_refresh() {
    if [[ "$AUTO_REFRESH" == true ]]; then
        AUTO_REFRESH=false
        log_structured info "Auto-refresh disabled"
    else
        AUTO_REFRESH=true
        log_structured info "Auto-refresh enabled"
    fi
}

################################################################################
# MAIN LOOP
################################################################################
main_loop() {
    local key last_refresh_time current_time
    last_refresh_time=$(date +%s)

    cursor_hide
    trap 'cursor_show; exit 0' EXIT INT TERM

    compose_layout

    while true; do
        # Non-blocking read with timeout for sensor refresh
        if read -rsn1 -t "$REFRESH_INTERVAL" key; then
            case "$key" in
                $'\x1b')  # Escape sequence
                    read -rsn2 -t 0.1 key2
                    case "$key2" in
                        '[A') nav_up; compose_layout ;;    # Up arrow
                        '[B') nav_down; compose_layout ;;  # Down arrow
                    esac
                    ;;
                'k'|'K') nav_up; compose_layout ;;
                'j'|'J') nav_down; compose_layout ;;
                '1') jump_to_category 0; compose_layout ;;
                '2') jump_to_category 1; compose_layout ;;
                '3') jump_to_category 2; compose_layout ;;
                '4') jump_to_category 3; compose_layout ;;
                '5') jump_to_category 4; compose_layout ;;
                '6') jump_to_category 5; compose_layout ;;
                '7') jump_to_category 6; compose_layout ;;
                '8') jump_to_category 7; compose_layout ;;
                'a'|'A')
                    toggle_auto_refresh
                    compose_layout
                    ;;
                'r'|'R')
                    cursor_show
                    clear
                    gum spin --spinner dot --title "Refreshing system data..." -- \
                        bash -c 'sleep 0.3'
                    refresh_inxi_data
                    refresh_live_metrics
                    log_structured info "Manual refresh" timestamp "$(date -Iseconds)"
                    cursor_hide
                    compose_layout
                    ;;
                'l'|'L')
                    cursor_show
                    log_show 2>/dev/null || gum style --foreground 245 "No log entries yet"
                    read -rsn1 -p "Press any key to continue..."
                    cursor_hide
                    compose_layout
                    ;;
                'q'|'Q')
                    cursor_show
                    log_structured info "Dashboard closed" session_duration "$(ps -o etime= -p $$)"
                    gum style --foreground 39 "Goodbye!"
                    exit 0
                    ;;
            esac
        else
            # Timeout - refresh sensors if auto-refresh enabled
            if [[ "$AUTO_REFRESH" == true ]]; then
                current_time=$(date +%s)
                if [[ $((current_time - last_refresh_time)) -ge $REFRESH_INTERVAL ]]; then
                    refresh_live_metrics
                    # Update sensor bar in place
                    cursor_save
                    cursor_goto $((TERM_ROWS - 2)) 1
                    clear_line
                    build_sensor_bar
                    cursor_restore
                    last_refresh_time=$current_time
                fi
            fi
        fi
    done
}

################################################################################
# INITIALIZATION
################################################################################
init_dashboard() {
    # Initialize logging
    LOG_FILE="/tmp/system_dashboard.log"
    log_init "$LOG_FILE"

    # Check dependencies
    check_dependencies
    check_terminal_size

    # Calculate panel width once (avoids repeated arithmetic in panel builders)
    PANEL_WIDTH=$((TERM_COLS - NAV_PANEL_WIDTH - 8))

    # Initial data collection
    echo ""
    gum style --foreground 39 --bold "🖥️  System Dashboard"
    gum style --foreground 245 "Loading system information..."

    refresh_inxi_data
    refresh_live_metrics

    log_structured info "Dashboard started" terminal "${TERM_COLS}x${TERM_ROWS}" auto_refresh "$AUTO_REFRESH"
}

################################################################################
# ENTRY POINT
################################################################################
init_dashboard
main_loop
