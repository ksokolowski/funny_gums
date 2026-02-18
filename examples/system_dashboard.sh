#!/usr/bin/env bash
# system_dashboard.sh - AIDA64/HWiNFO-style system information dashboard
# Demonstrates: sidebar layout, progress bars, color-coded temps, auto-refresh
# shellcheck disable=SC1091,SC2034
set -u

################################################################################
# CONFIGURATION
################################################################################
REFRESH_INTERVAL=5 # Sensor refresh interval in seconds
MIN_COLS=100       # Minimum terminal width required
MIN_ROWS=30        # Minimum terminal height required
NAV_PANEL_WIDTH=22 # Width of left navigation panel
INXI_GITHUB="https://github.com/smxi/inxi"

# Threshold configuration (centralized for easy tuning)
RESOURCE_WARN=70 # Warning threshold for CPU/RAM/Disk (%)
RESOURCE_CRIT=90 # Critical threshold for CPU/RAM/Disk (%)
SWAP_WARN=50     # Warning threshold for swap (%)
SWAP_CRIT=80     # Critical threshold for swap (%)
TEMP_WARN=70     # Warning threshold for temps (°C)
TEMP_CRIT=85     # Critical threshold for temps (°C)

################################################################################
# COLOR THEME (semantic colors for consistent styling)
################################################################################
# Panel section headers
CLR_HEADER=$'\e[1;38;5;39m'   # Bold cyan - section titles
CLR_SUBHEADER=$'\e[38;5;147m' # Light purple - subsection titles

# Labels and values
CLR_LABEL=$'\e[38;5;245m'    # Gray - field labels
CLR_VALUE=$'\e[38;5;255m'    # Bright white - normal values
CLR_HIGHLIGHT=$'\e[38;5;51m' # Cyan - highlighted values
CLR_ACCENT=$'\e[38;5;213m'   # Pink - accent values

# Status indicators
CLR_GOOD=$'\e[38;5;46m'  # Green - healthy/good status
CLR_WARN=$'\e[38;5;220m' # Yellow/Orange - warning status
CLR_CRIT=$'\e[38;5;196m' # Red - critical status
CLR_INFO=$'\e[38;5;39m'  # Blue - informational

# Hardware types
CLR_CPU=$'\e[38;5;208m'   # Orange - CPU related
CLR_GPU=$'\e[38;5;46m'    # Green - GPU related
CLR_MEM=$'\e[38;5;141m'   # Purple - Memory related
CLR_DISK=$'\e[38;5;39m'   # Blue - Storage related
CLR_NET=$'\e[38;5;45m'    # Cyan - Network related
CLR_POWER=$'\e[38;5;226m' # Yellow - Power related

# Decorative
CLR_BORDER=$'\e[38;5;240m' # Dark gray - borders/separators
CLR_DIM=$'\e[38;5;242m'    # Dim gray - less important info
CLR_ICON=$'\e[38;5;117m'   # Light blue - icons

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
source "$SCRIPT_DIR/../funny_gums.sh"
source "$LIB_DIR/core/sh/gum_wrapper.sh"

# Detect terminal mode for proper emoji width handling
detect_terminal_mode

################################################################################
# TEMPORARY DIRECTORY (parallel data fetching — prefer RAM disk)
################################################################################
if [[ -d /dev/shm ]]; then
    TMP_DIR=$(mktemp -d -p /dev/shm -t funny_gums_dashboard.XXXXXX)
else
    TMP_DIR=$(mktemp -d -t funny_gums_dashboard.XXXXXX)
fi
trap 'rm -rf "$TMP_DIR"' EXIT

################################################################################
# STATE VARIABLES
################################################################################
CURRENT_CATEGORY=0    # Currently selected category index (0-7)
VIEW_MODE="overview"  # "overview" or "detail"
AUTO_REFRESH=true     # Toggle with 'A' key
INXI_CACHE=""         # Cached inxi output
TERM_COLS=0           # Terminal columns
TERM_ROWS=0           # Terminal rows
LAST_SENSOR_UPDATE="" # Timestamp of last sensor update

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

# DMI/BIOS info cache (refreshed once at startup, doesn't change during session)
DMI_BIOS_VENDOR=""
DMI_BIOS_VERSION=""
DMI_BIOS_DATE=""
DMI_BOARD_VENDOR=""
DMI_BOARD_NAME=""
DMI_CHASSIS_TYPE=""
DMI_SYSTEM_VENDOR=""
DMI_SYSTEM_NAME=""

# Power/Battery cache
LIVE_POWER_ON_AC=false
LIVE_BATTERY_PRESENT=false
LIVE_BATTERY_PERCENT=""
LIVE_BATTERY_STATUS=""
LIVE_BATTERY_TIME=""
LIVE_BATTERY_HEALTH=""

# GPU detailed metrics (NVIDIA/AMD)
LIVE_GPU_NAME=""
LIVE_GPU_UTIL=""
LIVE_GPU_VRAM_USED=""
LIVE_GPU_VRAM_TOTAL=""
LIVE_GPU_POWER=""
LIVE_GPU_FAN=""

# Thermal zones cache
declare -a LIVE_THERMAL_ZONES=()

# Fan speeds cache (from sensors)
declare -a LIVE_FAN_SPEEDS=()

# All temperature readings (chip|sensor|temp)
declare -a LIVE_ALL_TEMPS=()

# GPU clock speeds (NVIDIA)
LIVE_GPU_CLOCK_CORE=""
LIVE_GPU_CLOCK_MEM=""
LIVE_GPU_DRIVER=""

# Drive health cache (device|health|temp)
declare -A LIVE_DRIVE_HEALTH=()
declare -A LIVE_DRIVE_SMART=()

# Calculated dimensions (set once at startup)
PANEL_WIDTH=0

# Category definitions: name, icon, inxi_section
# Use emoji variables for proper VS16 handling across terminals
declare -a CATEGORIES=(
    "System|$EMOJI_SERVER|System"
    "Motherboard|$EMOJI_CPU|Motherboard"
    "CPU|$EMOJI_CPU|CPU"
    "Memory|$EMOJI_MEMORY|Memory"
    "Storage|$EMOJI_DISK_COL|Drives"
    "Graphics|$EMOJI_GPU|Graphics"
    "Audio|$EMOJI_SPEAKER|Audio"
    "Network|$EMOJI_NETWORK|Network"
    "Power|$EMOJI_POWER|Power"
    "Sensors|$EMOJI_TEMP|Sensors"
)

################################################################################
# DEPENDENCY CHECKS
################################################################################
check_dependencies() {
    if ! command -v inxi &>/dev/null; then
        echo ""
        gum_exec_style --foreground 196 --bold "ERROR: inxi is required but not installed"
        echo ""
        gum_exec_style --foreground 245 "Install inxi from your package manager or visit:"
        gum_exec_style --foreground 39 --underline "$INXI_GITHUB"
        echo ""
        gum_exec_style --foreground 245 "Example installation:"
        gum_exec_style --foreground 255 "  Ubuntu/Debian: sudo apt install inxi"
        gum_exec_style --foreground 255 "  Fedora:        sudo dnf install inxi"
        gum_exec_style --foreground 255 "  Arch:          sudo pacman -S inxi"
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
        gum_exec_style --foreground 214 --bold "Terminal too small: ${TERM_COLS}x${TERM_ROWS}"
        echo ""
        gum_exec_style --foreground 245 "This dashboard requires at least ${MIN_COLS}x${MIN_ROWS}."
        gum_exec_style --foreground 245 "Please resize your terminal or use inxi directly:"
        echo ""
        gum_exec_style --foreground 39 "  inxi -Fxxxz"
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

# Refresh DMI/BIOS data (static, only called once at startup)
refresh_dmi_data() {
    if dmidecode_available; then
        DMI_BIOS_VENDOR=$(dmidecode_get_bios_vendor 2>/dev/null)
        DMI_BIOS_VERSION=$(dmidecode_get_bios_version 2>/dev/null)
        DMI_BIOS_DATE=$(dmidecode_get_bios_date 2>/dev/null)
        DMI_BOARD_VENDOR=$(dmidecode_get_board_vendor 2>/dev/null)
        DMI_BOARD_NAME=$(dmidecode_get_board_name 2>/dev/null)
        DMI_CHASSIS_TYPE=$(dmidecode_get_chassis_type 2>/dev/null)
        DMI_SYSTEM_VENDOR=$(dmidecode_get_system_vendor 2>/dev/null)
        DMI_SYSTEM_NAME=$(dmidecode_get_system_name 2>/dev/null)
    fi
}

refresh_live_metrics() {
    # 1. Start background jobs for slow/independent data fetches
    # CPU Usage (sleeps 0.1s internally)
    (get_cpu_usage_live >"$TMP_DIR/cpu_usage") &
    local pid_cpu=$!

    # Sensors (if available) — populates cache for all subsequent temp/fan queries
    local pid_sensors=""
    if sensors_available; then
        (sensors >"$TMP_DIR/sensors" 2>/dev/null) &
        pid_sensors=$!
    fi

    # Disk Usage
    (get_root_disk_usage_live >"$TMP_DIR/disk_root") &
    local pid_disk=$!

    # Memory/Swap
    (get_memory_usage_live >"$TMP_DIR/mem") &
    local pid_mem=$!

    (get_swap_usage_live >"$TMP_DIR/swap") &
    local pid_swap=$!

    # 2. Wait for background jobs
    wait "$pid_cpu"
    [[ -n "$pid_sensors" ]] && wait "$pid_sensors"
    wait "$pid_disk"
    wait "$pid_mem"
    wait "$pid_swap"

    # 3. Read results and populate caches
    LIVE_CPU_PERCENT=$(<"$TMP_DIR/cpu_usage")

    if [[ -n "$pid_sensors" ]]; then
        _SENSORS_CACHE=$(<"$TMP_DIR/sensors")
    fi

    local disk_used disk_total
    read -r disk_used disk_total LIVE_DISK_PERCENT <<<"$(<"$TMP_DIR/disk_root")"
    LIVE_DISK_USED=$(format_bytes "$disk_used")
    LIVE_DISK_TOTAL=$(format_bytes "$disk_total")

    read -r LIVE_MEM_USED_KB LIVE_MEM_TOTAL_KB LIVE_MEM_PERCENT <<<"$(<"$TMP_DIR/mem")"
    LIVE_MEM_USED_HR=$(format_kb "$LIVE_MEM_USED_KB")
    LIVE_MEM_TOTAL_HR=$(format_kb "$LIVE_MEM_TOTAL_KB")

    read -r LIVE_SWAP_USED_KB LIVE_SWAP_TOTAL_KB LIVE_SWAP_PERCENT <<<"$(<"$TMP_DIR/swap")"
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        LIVE_SWAP_USED_HR=$(format_kb "$LIVE_SWAP_USED_KB")
        LIVE_SWAP_TOTAL_HR=$(format_kb "$LIVE_SWAP_TOTAL_KB")
    else
        LIVE_SWAP_USED_HR=""
        LIVE_SWAP_TOTAL_HR=""
    fi

    # 4. Dependent/fast calculations (sensors cache is now populated from step 3)
    LIVE_CPU_TEMP=$(get_cpu_temp_live)
    LIVE_GPU_TEMP=$(get_gpu_temp_live)

    # CPU frequency
    LIVE_CPU_FREQ=$(get_cpu_freq_live)

    # Power/Battery status
    if power_available; then
        if power_on_ac; then
            LIVE_POWER_ON_AC=true
        else
            LIVE_POWER_ON_AC=false
        fi

        if power_has_battery; then
            LIVE_BATTERY_PRESENT=true
            LIVE_BATTERY_PERCENT=$(power_get_battery_percent)
            LIVE_BATTERY_STATUS=$(power_get_battery_status)
            LIVE_BATTERY_TIME=$(power_get_battery_time)
            LIVE_BATTERY_HEALTH=$(power_get_battery_health)
        else
            LIVE_BATTERY_PRESENT=false
        fi

        # Thermal zones
        LIVE_THERMAL_ZONES=()
        while IFS='|' read -r zone temp type; do
            [[ -n "$zone" ]] && LIVE_THERMAL_ZONES+=("$zone|$temp|$type")
        done < <(power_get_thermal_zones 2>/dev/null)
    fi

    # Detailed GPU metrics
    if nvidia_available; then
        LIVE_GPU_NAME=$(nvidia_get_gpu_name 2>/dev/null)
        LIVE_GPU_UTIL=$(nvidia_get_utilization 2>/dev/null)
        LIVE_GPU_POWER=$(nvidia_get_power_draw 2>/dev/null)
        LIVE_GPU_FAN=$(nvidia_get_fan_speed 2>/dev/null)
        LIVE_GPU_DRIVER=$(nvidia_get_driver_version 2>/dev/null)
        local vram_used vram_total
        read -r vram_used vram_total <<<"$(nvidia_get_memory_usage 2>/dev/null)"
        if [[ -n "$vram_used" && -n "$vram_total" ]]; then
            LIVE_GPU_VRAM_USED="${vram_used} MiB"
            LIVE_GPU_VRAM_TOTAL="${vram_total} MiB"
        fi
        # GPU clock speeds
        local gpu_clk mem_clk
        read -r gpu_clk mem_clk <<<"$(nvidia_get_clocks 2>/dev/null)"
        LIVE_GPU_CLOCK_CORE="$gpu_clk"
        LIVE_GPU_CLOCK_MEM="$mem_clk"
    elif amd_gpu_available; then
        LIVE_GPU_NAME="AMD GPU"
        LIVE_GPU_POWER=$(amd_get_power 2>/dev/null)
        LIVE_GPU_FAN=$(amd_get_fan_speed 2>/dev/null)
        local vram_used vram_total
        read -r vram_used vram_total <<<"$(amd_get_vram_usage 2>/dev/null)"
        if [[ -n "$vram_used" && -n "$vram_total" ]]; then
            LIVE_GPU_VRAM_USED=$(format_bytes "$vram_used")
            LIVE_GPU_VRAM_TOTAL=$(format_bytes "$vram_total")
        fi
    fi

    # Fan speeds from lm-sensors
    if sensors_available; then
        LIVE_FAN_SPEEDS=()
        while IFS='|' read -r fan rpm; do
            [[ -n "$fan" ]] && LIVE_FAN_SPEEDS+=("$fan|$rpm")
        done < <(sensors_get_fan_speeds 2>/dev/null)

        # All temperature readings
        LIVE_ALL_TEMPS=()
        while IFS='|' read -r chip sensor temp; do
            [[ -n "$chip" ]] && LIVE_ALL_TEMPS+=("$chip|$sensor|$temp")
        done < <(sensors_get_all_temps 2>/dev/null)
    fi

    # Drive health (SMART data) - only check occasionally as it's slow
    if smartctl_available; then
        while IFS='|' read -r drive_name _ _ _; do
            [[ -z "$drive_name" ]] && continue
            local health
            health=$(smartctl_get_health "$drive_name" 2>/dev/null)
            [[ -n "$health" ]] && LIVE_DRIVE_HEALTH["$drive_name"]="$health"
        done < <(get_physical_drives 2>/dev/null)
    fi

    LAST_SENSOR_UPDATE=$(date '+%H:%M:%S')
}

################################################################################
# CATEGORY CONTENT BUILDERS
################################################################################
get_category_content() {
    local cat_idx="$1"
    local cat_def="${CATEGORIES[$cat_idx]}"
    local cat_name cat_icon cat_section
    IFS='|' read -r cat_name cat_icon cat_section <<<"$cat_def"

    case "$cat_section" in
    "System") inxi_parse_system_csv ;;
    "Motherboard")
        echo "Item,Value"
        if dmidecode_available; then
            echo "Board Vendor,${DMI_BOARD_VENDOR:-N/A}"
            echo "Board Name,${DMI_BOARD_NAME:-N/A}"
            echo "BIOS Vendor,${DMI_BIOS_VENDOR:-N/A}"
            echo "BIOS Version,${DMI_BIOS_VERSION:-N/A}"
            echo "BIOS Date,${DMI_BIOS_DATE:-N/A}"
            echo "Chassis Type,${DMI_CHASSIS_TYPE:-N/A}"
        else
            echo "Status,dmidecode not available"
        fi
        ;;
    "CPU") inxi_parse_cpu_csv ;;
    "Memory")
        echo "Item,Value"
        # Parse memory info including configured speed
        if dmidecode_available; then
            dmidecode_get_memory_info | while IFS='|' read -r slot channel size type speed mfr conf_speed; do
                [[ "$size" == "No Module Installed" ]] && continue
                echo "Slot,$slot (Channel $channel)"
                echo "Size,$size"
                echo "Type,$type"
                echo "Speed,${speed} (Configured: ${conf_speed})"
                echo "Manufacturer,$mfr"
                echo "---,---"
            done
        else
            inxi_parse_memory_csv
        fi
        ;;
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
    "Audio") inxi_parse_audio_csv ;;
    "Network")
        inxi_parse_network_csv

        # Network Temperatures
        local net_temps
        net_temps=$(sensors_get_network_temps)
        if [[ -n "$net_temps" ]]; then
            echo ""
            echo "Temperatures,Values" # Header for CSV-like parsing if re-used or just appending check
            # Actually inxi_parse_network_csv likely outputs a built stream or similar.
            # System dashboard uses `get_category_content` which outputs CSV or lines?
            # Ah, `inxi_parse_network_csv` probably outputs styled text or CSV?
            # Let's check `get_category_content` structure.
            # It seems `inxi_parse_*` functions handle the output.
            # Since we can't easily append to inxi's output table structure defined elsewhere,
            # we'll just print a separate section label if needed or just lines.
            # But wait, `build_system_panel` and others consume this output.
            # `get_category_content` is called by `build_*_panel`??
            # No, `build_graphics_panel` etc seem to build their own.
            # `get_category_content` seems to be used for the "Details" sub-section of panels.

            # So we should modify `build_network_panel` if it exists, or update `inxi_parse_network_csv`
            # but that's in `system.sh` probably?

            # Let's just output it here as Key,Value which `get_category_content` callers seem to expect (CSV format).
            local i=1
            for temp in $net_temps; do
                echo "Temp (Sensor $i),${temp}°C"
                ((i++))
            done
        fi
        ;;
    "Power")
        echo "Item,Value"
        if power_available; then
            if power_on_ac; then
                echo "Power Source,AC Adapter"
            else
                echo "Power Source,Battery"
            fi
            if power_has_battery; then
                echo "Battery Level,${POWER_BATTERY_PERCENT:-?}%"
                echo "Battery Status,${POWER_BATTERY_STATUS:-Unknown}"
                [[ -n "${POWER_BATTERY_TIME:-}" ]] && echo "Time Remaining,$POWER_BATTERY_TIME"
                [[ -n "${POWER_BATTERY_HEALTH:-}" ]] && echo "Battery Health,$POWER_BATTERY_HEALTH%"
            else
                echo "Battery,Not present"
            fi
        else
            echo "Status,Power tools not available"
        fi
        ;;
    "Sensors") inxi_parse_sensors_csv ;;
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
    local title="$EMOJI_SERVER  System Dashboard"
    local timestamp
    timestamp=$(date '+%H:%M:%S')

    local mode_indicator
    if [[ "$VIEW_MODE" == "overview" ]]; then
        mode_indicator="Overview"
    else
        local cat_def="${CATEGORIES[$CURRENT_CATEGORY]}"
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<<"$cat_def"
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

    gum_exec_style --border double --border-foreground 39 --width "$header_width" \
        --padding "0 1" "$header_text"
}

build_nav_panel() {
    local lines=""
    local i=0

    lines+="  ${BOLD}Categories${RESET}\n"
    lines+="  ──────────────\n"

    for cat_def in "${CATEGORIES[@]}"; do
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<<"$cat_def"

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

    echo -e "$lines" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 240 \
        --width "$NAV_PANEL_WIDTH" --height 22 --padding "0 1"
}

build_system_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_SERVER} System Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # Get system info
    local host os kernel desktop uptime_str
    host=$(hostname 2>/dev/null || echo "Unknown")
    os=$(grep -E "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
    kernel=$(uname -r 2>/dev/null || echo "Unknown")
    desktop="${XDG_CURRENT_DESKTOP:-Unknown}"
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

    content+="  ${CLR_LABEL}Host:${RESET}      ${CLR_HIGHLIGHT}$host${RESET}\n"
    content+="  ${CLR_LABEL}OS:${RESET}        ${CLR_VALUE}$os${RESET}\n"
    content+="  ${CLR_LABEL}Kernel:${RESET}    ${CLR_ACCENT}$kernel${RESET}\n"
    content+="  ${CLR_LABEL}Desktop:${RESET}   ${CLR_VALUE}$desktop${RESET}\n"
    content+="  ${CLR_LABEL}Uptime:${RESET}    ${CLR_GOOD}$uptime_str${RESET}\n"

    # Hardware info from dmidecode (if available)
    if [[ -n "$DMI_BOARD_NAME" || -n "$DMI_SYSTEM_NAME" ]]; then
        content+="\n${CLR_SUBHEADER}${EMOJI_CPU} Hardware${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        [[ -n "$DMI_BOARD_VENDOR" && -n "$DMI_BOARD_NAME" ]] && content+="  ${CLR_LABEL}Board:${RESET}     ${CLR_VALUE}$DMI_BOARD_VENDOR ${CLR_HIGHLIGHT}$DMI_BOARD_NAME${RESET}\n"
        [[ -n "$DMI_CHASSIS_TYPE" ]] && content+="  ${CLR_LABEL}Chassis:${RESET}   ${CLR_VALUE}$DMI_CHASSIS_TYPE${RESET}\n"
        [[ -n "$DMI_BIOS_VENDOR" ]] && content+="  ${CLR_LABEL}BIOS:${RESET}      ${CLR_DIM}$DMI_BIOS_VENDOR${RESET} ${CLR_VALUE}$DMI_BIOS_VERSION${RESET}\n"
    fi

    content+="\n${CLR_SUBHEADER}📊 Resource Usage${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # CPU gauge with frequency
    local cpu_gauge freq_str=""
    cpu_gauge=$(ui_gauge_colored "$LIVE_CPU_PERCENT" 100 25 "CPU" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    [[ -n "$LIVE_CPU_FREQ" ]] && freq_str="  ${CLR_CPU}${LIVE_CPU_FREQ} MHz${RESET}"
    content+="  $cpu_gauge$freq_str\n\n"

    # Memory gauge (using cached formatted values)
    local mem_gauge
    mem_gauge=$(ui_gauge_colored "$LIVE_MEM_PERCENT" 100 25 "RAM" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $mem_gauge  ${CLR_MEM}$LIVE_MEM_USED_HR${RESET} / ${CLR_DIM}$LIVE_MEM_TOTAL_HR${RESET}\n\n"

    # Disk gauge
    local disk_gauge
    disk_gauge=$(ui_gauge_colored "$LIVE_DISK_PERCENT" 100 25 "Disk" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $disk_gauge  ${CLR_DISK}$LIVE_DISK_USED${RESET} / ${CLR_DIM}$LIVE_DISK_TOTAL${RESET}\n\n"

    # Swap gauge (using cached formatted values)
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        local swap_gauge
        swap_gauge=$(ui_gauge_colored "$LIVE_SWAP_PERCENT" 100 25 "Swap" "$SWAP_WARN" "$SWAP_CRIT")
        content+="  $swap_gauge  ${CLR_MEM}$LIVE_SWAP_USED_HR${RESET} / ${CLR_DIM}$LIVE_SWAP_TOTAL_HR${RESET}\n"
    else
        content+="  ${CLR_DIM}Swap:    Not configured${RESET}\n"
    fi

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_cpu_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_CPU} CPU Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # Get CPU model from inxi cache
    local cpu_model cores threads
    cpu_model=$(echo "$INXI_CACHE" | grep -A5 "^CPU:" | grep "model:" | sed 's/.*model: //' | cut -d' ' -f1-6)
    [[ -z "$cpu_model" ]] && cpu_model=$(lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:[[:space:]]*//')
    cores=$(lscpu 2>/dev/null | grep "^Core(s) per socket:" | awk '{print $4}')
    threads=$(lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}')

    content+="  ${CLR_LABEL}Model:${RESET}     ${CLR_CPU}$cpu_model${RESET}\n"
    [[ -n "$cores" ]] && content+="  ${CLR_LABEL}Cores:${RESET}     ${CLR_HIGHLIGHT}$cores${RESET} cores, ${CLR_HIGHLIGHT}$threads${RESET} threads\n"
    content+="\n"

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
        content+="  ${CLR_LABEL}Frequency:${RESET} ${CLR_CPU}${LIVE_CPU_FREQ} MHz${RESET}\n\n"
    fi

    # Load average with color coding
    local load_avg load1
    load_avg=$(get_load_avg_live)
    load1=$(echo "$load_avg" | cut -d' ' -f1)
    local load_color="$CLR_GOOD"
    if [[ -n "$cores" ]]; then
        local load_int=${load1%.*}
        [[ $load_int -ge $cores ]] && load_color="$CLR_WARN"
        [[ $load_int -ge $((cores * 2)) ]] && load_color="$CLR_CRIT"
    fi
    content+="  ${CLR_LABEL}Load Avg:${RESET}  ${load_color}$load_avg${RESET}\n\n"

    # Per-core temps if available from sensors
    if [[ ${#LIVE_ALL_TEMPS[@]} -gt 0 ]]; then
        local has_core_temps=false
        for temp_data in "${LIVE_ALL_TEMPS[@]}"; do
            IFS='|' read -r chip sensor temp <<<"$temp_data"
            if [[ "$sensor" == Core* ]]; then
                if ! $has_core_temps; then
                    content+="${CLR_SUBHEADER}Core Temperatures${RESET}\n"
                    has_core_temps=true
                fi
                local temp_color
                temp_color=$(_ui_threshold_color "$temp" "$TEMP_WARN" "$TEMP_CRIT")
                content+="  ${CLR_DIM}$sensor:${RESET} ${temp_color}${temp}°C${RESET}  "
            fi
        done
        $has_core_temps && content+="\n\n"
    fi

    # Additional CPU info from inxi
    content+="${CLR_SUBHEADER}Details${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
    local cpu_details
    cpu_details=$(get_category_content 2 | tail -n +2 | head -10 |
        awk -F',' '{if(NF>=2) printf "  \033[38;5;245m%-12s\033[0m %s\n", $1":", $2}')
    content+="$cpu_details"

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 208 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_memory_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_MEMORY} Memory Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # RAM usage (using cached formatted values)
    local mem_gauge
    mem_gauge=$(ui_gauge_colored "$LIVE_MEM_PERCENT" 100 30 "RAM" "$RESOURCE_WARN" "$RESOURCE_CRIT")
    content+="  $mem_gauge\n"
    content+="  ${CLR_LABEL}Used:${RESET} ${CLR_MEM}$LIVE_MEM_USED_HR${RESET} / ${CLR_LABEL}Total:${RESET} ${CLR_HIGHLIGHT}$LIVE_MEM_TOTAL_HR${RESET}\n\n"

    # RAM Temperatures (if available)
    local ram_temps
    ram_temps=$(sensors_get_ram_temps)
    if [[ -n "$ram_temps" ]]; then
        content+="${CLR_SUBHEADER}Module Temperatures${RESET}\n"
        local i=1
        for temp in $ram_temps; do
            local temp_color
            temp_color=$(_ui_threshold_color "$temp" "$TEMP_WARN" "$TEMP_CRIT")
            content+="  ${CLR_DIM}Module $i:${RESET} ${temp_color}${temp}°C${RESET}"
            ((i++))
        done
        content+="\n\n"
    fi

    # Swap usage (using cached formatted values)
    if [[ "$LIVE_SWAP_TOTAL_KB" -gt 0 ]]; then
        local swap_gauge
        swap_gauge=$(ui_gauge_colored "$LIVE_SWAP_PERCENT" 100 30 "Swap" "$SWAP_WARN" "$SWAP_CRIT")
        content+="  $swap_gauge\n"
        content+="  ${CLR_LABEL}Used:${RESET} ${CLR_MEM}$LIVE_SWAP_USED_HR${RESET} / ${CLR_LABEL}Total:${RESET} ${CLR_DIM}$LIVE_SWAP_TOTAL_HR${RESET}\n\n"
    else
        content+="  ${CLR_DIM}Swap: Not configured${RESET}\n\n"
    fi

    # Buffers/cache info
    local buffers cached available
    buffers=$(awk '/^Buffers:/ {printf "%.1f MiB", $2/1024}' /proc/meminfo 2>/dev/null)
    cached=$(awk '/^Cached:/ {printf "%.1f MiB", $2/1024}' /proc/meminfo 2>/dev/null)
    available=$(awk '/^MemAvailable:/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    content+="${CLR_SUBHEADER}Cache & Buffers${RESET}\n"
    content+="  ${CLR_LABEL}Available:${RESET} ${CLR_GOOD}$available${RESET}\n"
    content+="  ${CLR_LABEL}Buffers:${RESET}   ${CLR_VALUE}$buffers${RESET}\n"
    content+="  ${CLR_LABEL}Cached:${RESET}    ${CLR_VALUE}$cached${RESET}\n\n"

    # Additional memory info from inxi
    content+="${CLR_SUBHEADER}Details${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
    local mem_details
    mem_details=$(get_category_content 3 | tail -n +2 | head -10 |
        awk -F',' '{if(NF>=2) printf "  \033[38;5;245m%-12s\033[0m \033[38;5;141m%s\033[0m\n", $1":", $2}')
    content+="$mem_details"

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 141 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_storage_panel() {
    local content=""
    local bar_width=35

    content+="${CLR_HEADER}${EMOJI_DISK_HEAD} Storage - Physical Drives${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # Iterate through physical drives
    while IFS='|' read -r drive_name size_bytes model drive_type; do
        [[ -z "$drive_name" ]] && continue

        local size_hr icon type_color
        size_hr=$(format_bytes "$size_bytes")

        case "$drive_type" in
        nvme)
            icon="⚡"
            type_color="${CLR_GOOD}"
            ;;
        ssd)
            icon="💾"
            type_color="${CLR_INFO}"
            ;;
        hdd)
            icon="💿"
            type_color="${CLR_WARN}"
            ;;
        *)
            icon="📀"
            type_color="${CLR_DIM}"
            ;;
        esac

        # Drive header
        content+="  ${CLR_DISK}$icon ${BOLD}$model${RESET} ${CLR_DIM}(${CLR_HIGHLIGHT}$size_hr${CLR_DIM} - ${type_color}${drive_type^^}${CLR_DIM})${RESET}\n"

        # Try to get detailed info from hdparm (for SATA drives)
        if hdparm_available && [[ "$drive_type" != "nvme" ]]; then
            local serial firmware
            serial=$(hdparm_get_serial "$drive_name" 2>/dev/null)
            firmware=$(hdparm_get_firmware "$drive_name" 2>/dev/null)
            if [[ -n "$serial" || -n "$firmware" ]]; then
                content+="     ${CLR_DIM}"
                [[ -n "$serial" ]] && content+="S/N: ${CLR_VALUE}$serial${CLR_DIM}"
                [[ -n "$serial" && -n "$firmware" ]] && content+=" │ "
                [[ -n "$firmware" ]] && content+="FW: ${CLR_VALUE}$firmware${CLR_DIM}"
                content+="${RESET}\n"
            fi
        fi

        # SMART health status
        local health="${LIVE_DRIVE_HEALTH[$drive_name]:-}"
        if [[ -n "$health" ]]; then
            local health_color health_icon
            if [[ "$health" == "PASSED" ]]; then
                health_color="$CLR_GOOD"
                health_icon="✓"
            else
                health_color="$CLR_CRIT"
                health_icon="✗"
            fi
            content+="     ${CLR_LABEL}SMART:${RESET} ${health_color}${health_icon} $health${RESET}"
        fi

        # Try to get drive temperature
        local drive_temp
        drive_temp=$(get_drive_temp "$drive_name" 2>/dev/null)
        if [[ -n "$drive_temp" ]]; then
            local temp_color
            temp_color=$(_ui_threshold_color "$drive_temp" "$TEMP_WARN" "$TEMP_CRIT")
            [[ -n "$health" ]] && content+="  │  "
            content+="${CLR_LABEL}Temp:${RESET} ${temp_color}${drive_temp}°C${RESET}"
        fi
        [[ -n "$health" || -n "$drive_temp" ]] && content+="\n"

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
            for ((i = 0; i < bar_width; i++)); do content+="${DIM}░${RESET}"; done
        fi
        content+="]\n"

        # Add partition details
        content+="$part_lines"
        content+="\n"

    done < <(get_physical_drives)

    # Legend
    content+="${BOLD}Legend:${RESET} "
    content+=$(ui_fs_legend)

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 39 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_graphics_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_GPU} Graphics Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # GPU Name (if available from nvidia-smi or AMD)
    if [[ -n "$LIVE_GPU_NAME" ]]; then
        content+="  ${CLR_GPU}${BOLD}$LIVE_GPU_NAME${RESET}\n"
        [[ -n "$LIVE_GPU_DRIVER" ]] && content+="  ${CLR_LABEL}Driver:${RESET} ${CLR_VALUE}$LIVE_GPU_DRIVER${RESET}\n"
        content+="\n"
    fi

    # GPU temperature (if available)
    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        local gpu_temp_display
        gpu_temp_display=$(ui_temp_gauge "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "Temp")
        content+="  $gpu_temp_display\n"
    fi

    # GPU Utilization
    if [[ -n "$LIVE_GPU_UTIL" ]]; then
        local gpu_util_gauge
        gpu_util_gauge=$(ui_gauge_colored "$LIVE_GPU_UTIL" 100 25 "Usage" "$RESOURCE_WARN" "$RESOURCE_CRIT")
        content+="  $gpu_util_gauge\n"
    fi

    # VRAM Usage
    if [[ -n "$LIVE_GPU_VRAM_USED" && -n "$LIVE_GPU_VRAM_TOTAL" ]]; then
        # Extract numeric values for percentage calculation
        local vram_used_val vram_total_val vram_pct
        vram_used_val=$(echo "$LIVE_GPU_VRAM_USED" | grep -oE '[0-9]+' | head -1)
        vram_total_val=$(echo "$LIVE_GPU_VRAM_TOTAL" | grep -oE '[0-9]+' | head -1)
        if [[ -n "$vram_total_val" && "$vram_total_val" -gt 0 ]]; then
            vram_pct=$((vram_used_val * 100 / vram_total_val))
            local vram_gauge
            vram_gauge=$(ui_gauge_colored "$vram_pct" 100 25 "VRAM" "$RESOURCE_WARN" "$RESOURCE_CRIT")
            content+="  $vram_gauge  ${CLR_GPU}$LIVE_GPU_VRAM_USED${RESET} / ${CLR_DIM}$LIVE_GPU_VRAM_TOTAL${RESET}\n"
        fi
    fi

    content+="\n"

    # Clock speeds (NVIDIA)
    if [[ -n "$LIVE_GPU_CLOCK_CORE" || -n "$LIVE_GPU_CLOCK_MEM" ]]; then
        content+="${CLR_SUBHEADER}Clock Speeds${RESET}\n"
        [[ -n "$LIVE_GPU_CLOCK_CORE" ]] && content+="  ${CLR_LABEL}Core:${RESET}   ${CLR_GPU}${LIVE_GPU_CLOCK_CORE} MHz${RESET}\n"
        [[ -n "$LIVE_GPU_CLOCK_MEM" ]] && content+="  ${CLR_LABEL}Memory:${RESET} ${CLR_GPU}${LIVE_GPU_CLOCK_MEM} MHz${RESET}\n"
        content+="\n"
    fi

    # Additional GPU metrics
    if [[ -n "$LIVE_GPU_POWER" || -n "$LIVE_GPU_FAN" ]]; then
        content+="${CLR_SUBHEADER}Status${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        if [[ -n "$LIVE_GPU_POWER" ]]; then
            local power_int=${LIVE_GPU_POWER%.*}
            local power_color="$CLR_GOOD"
            [[ $power_int -gt 150 ]] && power_color="$CLR_WARN"
            [[ $power_int -gt 250 ]] && power_color="$CLR_CRIT"
            content+="  ${CLR_LABEL}Power Draw:${RESET}  ${power_color}${LIVE_GPU_POWER}W${RESET}\n"
        fi
        if [[ -n "$LIVE_GPU_FAN" ]]; then
            # Check if it's RPM (AMD) or percentage (NVIDIA)
            if [[ "$LIVE_GPU_FAN" =~ ^[0-9]+$ ]] && [[ "$LIVE_GPU_FAN" -gt 100 ]]; then
                content+="  ${CLR_LABEL}Fan Speed:${RESET}   ${CLR_INFO}${LIVE_GPU_FAN} RPM${RESET}\n"
            else
                local fan_color="$CLR_GOOD"
                [[ $LIVE_GPU_FAN -gt 50 ]] && fan_color="$CLR_WARN"
                [[ $LIVE_GPU_FAN -gt 80 ]] && fan_color="$CLR_CRIT"
                content+="  ${CLR_LABEL}Fan Speed:${RESET}   ${fan_color}${LIVE_GPU_FAN}%${RESET}\n"
            fi
        fi
        content+="\n"
    fi

    # Graphics info from inxi (as fallback/additional info)
    content+="${CLR_SUBHEADER}Details (via inxi)${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
    local gfx_details
    gfx_details=$(get_category_content 5 | tail -n +2 | head -10 |
        awk -F',' '{if(NF>=2) printf "  \033[38;5;245m%-12s\033[0m \033[38;5;46m%s\033[0m\n", $1":", $2}')
    content+="$gfx_details"

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 46 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_audio_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_SPEAKER} Audio Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # Audio info from inxi
    local audio_details
    audio_details=$(get_category_content 6 | tail -n +2 | head -15 |
        awk -F',' '{if(NF>=2) printf "  \033[38;5;245m%-12s\033[0m \033[38;5;213m%s\033[0m\n", $1":", $2}')
    content+="$audio_details"

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 213 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_network_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_NETWORK} Network - Physical Adapters${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    local has_interfaces=false

    # Iterate through physical network interfaces
    while IFS='|' read -r iface iface_type state speed mac ip_addr driver model; do
        [[ -z "$iface" ]] && continue
        has_interfaces=true

        local icon status_color status_icon status_label
        case "$iface_type" in
        wireless) icon="📶" ;;
        ethernet) icon="🔌" ;;
        *) icon="🌐" ;;
        esac

        status_color=$(_ui_net_status_color "$state")
        case "$state" in
        up)
            status_icon="●"
            status_label="Connected"
            ;;
        down)
            status_icon="○"
            status_label="Disconnected"
            ;;
        no-driver)
            status_icon="◌"
            status_label="No Driver"
            ;;
        *)
            status_icon="?"
            status_label="Unknown"
            ;;
        esac

        # Interface header
        content+="  ${CLR_NET}${BOLD}$icon $iface${RESET} - ${status_color}${status_icon} ${status_label}${RESET}\n"

        # Model/description (truncate to fit panel width)
        if [[ "$model" != "-" ]]; then
            local max_model_len=$((PANEL_WIDTH - 12)) # Account for padding/border
            [[ ${#model} -gt $max_model_len ]] && model="${model:0:$((max_model_len - 3))}..."
            content+="     ${CLR_DIM}$model${RESET}\n"
        fi

        # Connection details if up
        if [[ "$state" == "up" ]]; then
            local details=""
            if [[ "$ip_addr" != "-" ]]; then
                details+="${CLR_LABEL}IP:${RESET} ${CLR_HIGHLIGHT}$ip_addr${RESET}"
            fi
            if [[ "$speed" != "-" ]]; then
                [[ -n "$details" ]] && details+="  │  "
                details+="${CLR_LABEL}Speed:${RESET} ${CLR_GOOD}$speed${RESET}"
            fi
            [[ -n "$details" ]] && content+="     $details\n"

            # WiFi signal strength
            if [[ "$iface_type" == "wireless" ]]; then
                local signal
                signal=$(get_wifi_signal "$iface")
                if [[ -n "$signal" ]]; then
                    local signal_bar
                    signal_bar=$(ui_wifi_signal "$signal" 5)
                    content+="     ${CLR_LABEL}Signal:${RESET} $signal_bar\n"
                fi
            fi
        fi

        # MAC address (dimmed)
        [[ "$mac" != "-" ]] && content+="     ${CLR_DIM}MAC: $mac${RESET}\n"

        # Driver info
        [[ "$driver" != "-" ]] && content+="     ${CLR_DIM}Driver: $driver${RESET}\n"

        content+="\n"
    done < <(get_network_interfaces)

    # Fallback if no interfaces found
    if ! $has_interfaces; then
        content+="  ${CLR_DIM}No physical network adapters found${RESET}\n"
    fi

    # Legend
    content+="${CLR_SUBHEADER}Status:${RESET} "
    content+="${CLR_GOOD}● Connected${RESET}  "
    content+="${CLR_CRIT}○ Disconnected${RESET}  "
    content+="${CLR_WARN}◌ No Driver${RESET}"

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 45 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_motherboard_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_CPU} Motherboard & BIOS Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    if dmidecode_available; then
        # BIOS Section
        content+="${CLR_SUBHEADER}BIOS${RESET}\n"
        [[ -n "$DMI_BIOS_VENDOR" ]] && content+="  ${CLR_LABEL}Vendor:${RESET}      ${CLR_VALUE}$DMI_BIOS_VENDOR${RESET}\n"
        [[ -n "$DMI_BIOS_VERSION" ]] && content+="  ${CLR_LABEL}Version:${RESET}     ${CLR_HIGHLIGHT}$DMI_BIOS_VERSION${RESET}\n"
        [[ -n "$DMI_BIOS_DATE" ]] && content+="  ${CLR_LABEL}Date:${RESET}        ${CLR_DIM}$DMI_BIOS_DATE${RESET}\n"
        content+="\n"

        # Motherboard Section
        content+="${CLR_SUBHEADER}Motherboard${RESET}\n"
        [[ -n "$DMI_BOARD_VENDOR" ]] && content+="  ${CLR_LABEL}Manufacturer:${RESET} ${CLR_VALUE}$DMI_BOARD_VENDOR${RESET}\n"
        [[ -n "$DMI_BOARD_NAME" ]] && content+="  ${CLR_LABEL}Model:${RESET}        ${CLR_ACCENT}$DMI_BOARD_NAME${RESET}\n"
        content+="\n"

        # System Section
        content+="${CLR_SUBHEADER}System${RESET}\n"
        [[ -n "$DMI_SYSTEM_VENDOR" ]] && content+="  ${CLR_LABEL}Manufacturer:${RESET} ${CLR_VALUE}$DMI_SYSTEM_VENDOR${RESET}\n"
        [[ -n "$DMI_SYSTEM_NAME" ]] && content+="  ${CLR_LABEL}Product:${RESET}      ${CLR_HIGHLIGHT}$DMI_SYSTEM_NAME${RESET}\n"
        [[ -n "$DMI_CHASSIS_TYPE" ]] && content+="  ${CLR_LABEL}Chassis:${RESET}      ${CLR_INFO}$DMI_CHASSIS_TYPE${RESET}\n"
        content+="\n"

        # Memory Slots
        content+="${CLR_SUBHEADER}Memory Configuration${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        local mem_slots
        mem_slots=$(dmidecode_get_memory_slots 2>/dev/null)
        [[ -n "$mem_slots" ]] && content+="  ${CLR_LABEL}Total Slots:${RESET}  ${CLR_HIGHLIGHT}$mem_slots${RESET}\n"

        # Memory modules
        local mem_info
        mem_info=$(dmidecode_get_memory_info 2>/dev/null)
        if [[ -n "$mem_info" ]]; then
            content+="\n  ${CLR_SUBHEADER}Installed Modules:${RESET}\n"
            while IFS='|' read -r slot channel size mtype speed mfr conf_speed; do
                [[ -z "$slot" ]] && continue
                content+="    ${CLR_MEM}●${RESET} ${CLR_LABEL}${slot}/${channel}:${RESET} ${CLR_HIGHLIGHT}$size${RESET} ${CLR_VALUE}$mtype${RESET} @ ${CLR_ACCENT}$speed${RESET}"
                [[ "$mfr" != "-" ]] && content+=" ${CLR_DIM}($mfr)${RESET}"
                content+="\n"
            done <<<"$mem_info"
        fi
    else
        content+="  ${CLR_WARN}dmidecode not available or requires sudo${RESET}\n"
        content+="\n"
        content+="  ${CLR_DIM}Install dmidecode and run with sudo for${RESET}\n"
        content+="  ${CLR_DIM}detailed motherboard information.${RESET}\n"
    fi

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 147 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_power_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_POWER} Power Management${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    if power_available; then
        # AC Power Status
        content+="${CLR_SUBHEADER}Power Source${RESET}\n"
        if [[ "$LIVE_POWER_ON_AC" == true ]]; then
            content+="  ${CLR_LABEL}Status:${RESET}      ${CLR_GOOD}⚡ AC Power${RESET}\n"
        else
            content+="  ${CLR_LABEL}Status:${RESET}      ${CLR_POWER}🔋 Battery${RESET}\n"
        fi
        content+="\n"

        # Battery Information
        if [[ "$LIVE_BATTERY_PRESENT" == true ]]; then
            content+="${CLR_SUBHEADER}Battery${RESET}\n"
            content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"

            # Battery percentage with gauge
            if [[ -n "$LIVE_BATTERY_PERCENT" ]]; then
                local batt_gauge batt_color
                # Invert thresholds for battery (low is bad)
                if [[ "$LIVE_BATTERY_PERCENT" -lt 20 ]]; then
                    batt_color="$CLR_CRIT"
                elif [[ "$LIVE_BATTERY_PERCENT" -lt 40 ]]; then
                    batt_color="$CLR_WARN"
                else
                    batt_color="$CLR_GOOD"
                fi
                batt_gauge=$(ui_gauge "$LIVE_BATTERY_PERCENT" 100 25 "Charge")
                content+="  $batt_gauge ${batt_color}${LIVE_BATTERY_PERCENT}%${RESET}\n"
            fi

            # Status
            if [[ -n "$LIVE_BATTERY_STATUS" ]]; then
                local status_icon status_color
                case "$LIVE_BATTERY_STATUS" in
                Charging)
                    status_icon="⚡"
                    status_color="$CLR_GOOD"
                    ;;
                Discharging)
                    status_icon="🔋"
                    status_color="$CLR_POWER"
                    ;;
                Full)
                    status_icon="✓"
                    status_color="$CLR_GOOD"
                    ;;
                *)
                    status_icon="●"
                    status_color="$CLR_VALUE"
                    ;;
                esac
                content+="  ${CLR_LABEL}Status:${RESET}      ${status_color}${status_icon} ${LIVE_BATTERY_STATUS}${RESET}\n"
            fi

            # Time remaining
            if [[ -n "$LIVE_BATTERY_TIME" ]]; then
                content+="  ${CLR_LABEL}Time:${RESET}        ${CLR_HIGHLIGHT}$LIVE_BATTERY_TIME${RESET} remaining\n"
            fi

            # Battery health
            if [[ -n "$LIVE_BATTERY_HEALTH" ]]; then
                local health_color
                if [[ "$LIVE_BATTERY_HEALTH" -gt 80 ]]; then
                    health_color="$CLR_GOOD"
                elif [[ "$LIVE_BATTERY_HEALTH" -gt 50 ]]; then
                    health_color="$CLR_WARN"
                else
                    health_color="$CLR_CRIT"
                fi
                content+="  ${CLR_LABEL}Health:${RESET}      ${health_color}${LIVE_BATTERY_HEALTH}%${RESET} ${CLR_DIM}of design capacity${RESET}\n"
            fi
        else
            content+="${CLR_SUBHEADER}Battery${RESET}\n"
            content+="  ${CLR_DIM}No battery detected (desktop system)${RESET}\n"
        fi

        content+="\n"

        # Thermal Zones
        if [[ ${#LIVE_THERMAL_ZONES[@]} -gt 0 ]]; then
            content+="${CLR_SUBHEADER}Thermal Zones${RESET}\n"
            content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
            for zone_data in "${LIVE_THERMAL_ZONES[@]}"; do
                IFS='|' read -r zone temp type <<<"$zone_data"
                if [[ -n "$temp" && "$temp" != "-" ]]; then
                    local temp_color
                    temp_color=$(_ui_threshold_color "$temp" "$TEMP_WARN" "$TEMP_CRIT")
                    local type_str=""
                    [[ -n "$type" && "$type" != "-" ]] && type_str=" ${CLR_DIM}($type)${RESET}"
                    content+="  ${CLR_LABEL}$zone:${RESET}  ${temp_color}${temp}°C${RESET}${type_str}\n"
                fi
            done
        fi
    else
        content+="  ${CLR_WARN}Power tools not available${RESET}\n"
        content+="\n"
        content+="  ${CLR_DIM}Install acpi or upower for power${RESET}\n"
        content+="  ${CLR_DIM}management information.${RESET}\n"
    fi

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 226 \
        --width "$PANEL_WIDTH" --padding "1"
}

build_sensors_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_TEMP} Sensors Information${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    # Primary temperatures
    content+="${CLR_SUBHEADER}Primary Temperatures${RESET}\n"

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

    # All temperature readings from sensors
    if [[ ${#LIVE_ALL_TEMPS[@]} -gt 0 ]]; then
        content+="${CLR_SUBHEADER}All Temperature Sensors${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        local current_chip=""
        for temp_data in "${LIVE_ALL_TEMPS[@]}"; do
            IFS='|' read -r chip sensor temp <<<"$temp_data"
            if [[ "$chip" != "$current_chip" ]]; then
                current_chip="$chip"
                content+="  ${CLR_ACCENT}$chip${RESET}\n"
            fi
            local temp_color
            temp_color=$(_ui_threshold_color "$temp" "$TEMP_WARN" "$TEMP_CRIT")
            content+="    ${CLR_LABEL}$sensor:${RESET} ${temp_color}${temp}°C${RESET}\n"
        done
        content+="\n"
    fi

    # Fan speeds
    if [[ ${#LIVE_FAN_SPEEDS[@]} -gt 0 ]]; then
        content+="${CLR_SUBHEADER}Fan Speeds${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        for fan_data in "${LIVE_FAN_SPEEDS[@]}"; do
            IFS='|' read -r fan rpm <<<"$fan_data"
            local fan_color="$CLR_INFO"
            local rpm_int=${rpm:-0}
            if [[ $rpm_int -eq 0 ]]; then
                fan_color="$CLR_CRIT"
            elif [[ $rpm_int -lt 1000 ]]; then
                fan_color="$CLR_GOOD"
            elif [[ $rpm_int -gt 2500 ]]; then
                fan_color="$CLR_WARN"
            fi
            content+="  ${CLR_LABEL}$fan:${RESET} ${fan_color}${rpm} RPM${RESET}\n"
        done
        content+="\n"
    fi

    # Thermal Zones from power module
    if [[ ${#LIVE_THERMAL_ZONES[@]} -gt 0 ]]; then
        content+="${CLR_SUBHEADER}Thermal Zones${RESET}\n"
        content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        for zone_data in "${LIVE_THERMAL_ZONES[@]}"; do
            IFS='|' read -r zone temp type <<<"$zone_data"
            if [[ -n "$temp" && "$temp" != "-" ]]; then
                local temp_color
                temp_color=$(_ui_threshold_color "$temp" "$TEMP_WARN" "$TEMP_CRIT")
                local type_str=""
                [[ -n "$type" && "$type" != "-" ]] && type_str=" ${CLR_DIM}($type)${RESET}"
                content+="  ${CLR_LABEL}${zone}:${RESET} ${temp_color}${temp}°C${RESET}${type_str}\n"
            fi
        done
        content+="\n"
    fi

    # Sensor info from inxi
    content+="${CLR_SUBHEADER}System Summary (via inxi)${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n"
    local sensor_details
    sensor_details=$(get_category_content 9 | tail -n +2 | head -15 |
        awk -F',' '{if(NF>=2) printf "  \033[38;5;245m%-12s\033[0m %s\n", $1":", $2}')
    content+="$sensor_details"

    local panel_height=$((TERM_ROWS - 12)) # HACK: Force min height to push footer down
    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 196 \
        --width "$PANEL_WIDTH" --padding "1" --height "$panel_height"
}

build_main_panel() {
    case "$CURRENT_CATEGORY" in
    0) build_system_panel ;;
    1) build_motherboard_panel ;;
    2) build_cpu_panel ;;
    3) build_memory_panel ;;
    4) build_storage_panel ;;
    5) build_graphics_panel ;;
    6) build_audio_panel ;;
    7) build_network_panel ;;
    8) build_power_panel ;;
    9) build_sensors_panel ;;
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

    printf "\e[48;5;236m\e[38;5;245m %s  %b \e[0m" "$EMOJI_TEMP" "$sensor_str"
}

build_footer() {
    local help_text="↑↓/jk Navigate │ 1-9,0 Jump │ A: Auto-refresh │ R: Refresh │ L: Log │ Q: Quit"
    # We use a border here implicitly via gum_exec_style defaults (normal border)
    # The height is content(1) + border(2) = 3 lines
    gum_exec_style --foreground 245 --align center "$help_text"
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
            $'\x1b') # Escape sequence
                read -rsn2 -t 0.1 key2
                case "$key2" in
                '[A')
                    nav_up
                    compose_layout
                    ;; # Up arrow
                '[B')
                    nav_down
                    compose_layout
                    ;; # Down arrow
                esac
                ;;
            'k' | 'K')
                nav_up
                compose_layout
                ;;
            'j' | 'J')
                nav_down
                compose_layout
                ;;
            '1')
                jump_to_category 0
                compose_layout
                ;; # System
            '2')
                jump_to_category 1
                compose_layout
                ;; # Motherboard
            '3')
                jump_to_category 2
                compose_layout
                ;; # CPU
            '4')
                jump_to_category 3
                compose_layout
                ;; # Memory
            '5')
                jump_to_category 4
                compose_layout
                ;; # Storage
            '6')
                jump_to_category 5
                compose_layout
                ;; # Graphics
            '7')
                jump_to_category 6
                compose_layout
                ;; # Audio
            '8')
                jump_to_category 7
                compose_layout
                ;; # Network
            '9')
                jump_to_category 8
                compose_layout
                ;; # Power
            '0')
                jump_to_category 9
                compose_layout
                ;; # Sensors
            'a' | 'A')
                toggle_auto_refresh
                compose_layout
                ;;
            'r' | 'R')
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
            'l' | 'L')
                cursor_show
                log_show 2>/dev/null || gum_exec_style --foreground 245 "No log entries yet"
                read -rsn1 -p "Press any key to continue..."
                cursor_hide
                compose_layout
                ;;
            'q' | 'Q')
                cursor_show
                log_structured info "Dashboard closed" session_duration "$(ps -o etime= -p $$)"
                gum_exec_style --foreground 39 "Goodbye!"
                exit 0
                ;;
            esac
        else
            # Timeout - refresh sensors if auto-refresh enabled
            if [[ "$AUTO_REFRESH" == true ]]; then
                # Update terminal dimensions in case of resize
                TERM_ROWS=$(tput lines)
                TERM_COLS=$(tput cols)
                PANEL_WIDTH=$((TERM_COLS - NAV_PANEL_WIDTH - 8))

                current_time=$(date +%s)
                if [[ $((current_time - last_refresh_time)) -ge $REFRESH_INTERVAL ]]; then
                    refresh_live_metrics
                    # Update sensor bar in place
                    cursor_save
                    # Footer occupies 3 lines: (top border, text, bottom border)
                    # Sensor bar is immediately above footer (top border)
                    # So offset is: TERM_ROWS - footer_height(3) - sensor_padding(1)
                    cursor_goto $((TERM_ROWS - 4)) 1
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
    LOG_FILE="/tmp/system_dashboard_$(date +%Y-%m-%d_%H-%M-%S).log"
    log_init "$LOG_FILE"

    # Check dependencies
    check_dependencies
    check_terminal_size

    # Calculate panel width once (avoids repeated arithmetic in panel builders)
    PANEL_WIDTH=$((TERM_COLS - NAV_PANEL_WIDTH - 8))

    # Initial data collection
    echo ""
    gum_exec_style --foreground 39 --bold "$EMOJI_SERVER  System Dashboard"
    gum_exec_style --foreground 245 "Loading system information..."

    refresh_inxi_data
    refresh_dmi_data # Static DMI data (BIOS, motherboard) - only needs to run once
    refresh_live_metrics

    log_structured info "Dashboard started" terminal "${TERM_COLS}x${TERM_ROWS}" auto_refresh "$AUTO_REFRESH"
}

################################################################################
# ENTRY POINT
################################################################################
init_dashboard
main_loop
