#!/usr/bin/env bash
# system_dashboard.sh - AIDA64/HWiNFO-style system information dashboard
# Demonstrates: multi-pane layout, cursor control, auto-refresh sensors,
#               ui_table, ui_box, ui_join, ui_spin_type, log_structured
# shellcheck disable=SC1091,SC2034
set -u

################################################################################
# CONFIGURATION - Tune these for your preferences
################################################################################
REFRESH_INTERVAL=5           # Sensor refresh interval in seconds
MIN_COLS=80                  # Minimum terminal width required
NAV_PANEL_WIDTH=20           # Width of left navigation panel
HEADER_HEIGHT=3              # Height of header area
FOOTER_HEIGHT=2              # Height of footer/sensor bar
INXI_GITHUB="https://github.com/smxi/inxi"

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
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/cursor.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/inxi_helper.sh"

################################################################################
# STATE VARIABLES
################################################################################
CURRENT_CATEGORY=0           # Currently selected category index
VIEW_MODE="overview"         # "overview" or "detail"
SENSOR_PID=""                # Background sensor refresh process
INXI_CACHE=""                # Cached inxi output
TERM_COLS=0                  # Terminal columns
TERM_ROWS=0                  # Terminal rows
LAST_SENSOR_UPDATE=""        # Timestamp of last sensor update

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
    # Check for inxi
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

    # Check for gum
    if ! command -v gum &>/dev/null; then
        echo "ERROR: gum is required but not installed"
        echo "Visit: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

check_terminal_size() {
    TERM_COLS=$(tput cols)
    TERM_ROWS=$(tput lines)

    if [[ $TERM_COLS -lt $MIN_COLS ]]; then
        echo ""
        gum style --foreground 214 --bold "Terminal too narrow: ${TERM_COLS} columns"
        echo ""
        gum style --foreground 245 "This dashboard requires at least ${MIN_COLS} columns."
        gum style --foreground 245 "Please resize your terminal or use inxi directly:"
        echo ""
        gum style --foreground 39 "  inxi -Fxxxz"
        echo ""
        exit 1
    fi
}

################################################################################
# INXI DATA FUNCTIONS
################################################################################
refresh_inxi_data() {
    INXI_CACHE=$(inxi -Fxz -c0 2>/dev/null)
}

get_sensor_data() {
    # Quick sensor reading for status bar
    local sensors_raw
    sensors_raw=$(inxi -s -c0 2>/dev/null | grep -E "Temp|Fan|Power" | head -1)
    
    # Extract key metrics
    local cpu_temp gpu_temp fan_speed
    cpu_temp=$(echo "$sensors_raw" | grep -oP "cpu:\s*\K[0-9.]+\s*C" | head -1)
    gpu_temp=$(echo "$sensors_raw" | grep -oP "gpu:\s*\K[0-9.]+\s*C" | head -1)
    fan_speed=$(echo "$sensors_raw" | grep -oP "Fan:\s*\K[0-9]+" | head -1)
    
    # Build sensor string
    local sensor_str=""
    [[ -n "$cpu_temp" ]] && sensor_str+="CPU: ${cpu_temp}"
    [[ -n "$gpu_temp" ]] && sensor_str+=" │ GPU: ${gpu_temp}"
    [[ -n "$fan_speed" ]] && sensor_str+=" │ Fan: ${fan_speed} RPM"
    
    # Fallback if no sensors detected
    [[ -z "$sensor_str" ]] && sensor_str="Sensors: N/A"
    
    echo "$sensor_str"
}

get_category_content() {
    local cat_idx="$1"
    local cat_def="${CATEGORIES[$cat_idx]}"
    local cat_name cat_icon cat_section
    IFS='|' read -r cat_name cat_icon cat_section <<< "$cat_def"
    
    case "$cat_section" in
        "System")
            inxi_parse_system_csv
            ;;
        "CPU")
            inxi_parse_cpu_csv
            ;;
        "Memory")
            inxi_parse_memory_csv
            ;;
        "Drives")
            echo "Item,Value"
            inxi_get_section "Drives" | sed '1d' | sed 's/^[[:space:]]*//' | while read -r line; do
                if [[ -n "$line" ]]; then
                    echo "$line" | sed 's/: /,/' | head -1
                fi
            done
            echo ""
            echo "Partitions:"
            inxi_parse_partition_csv
            ;;
        "Graphics")
            inxi_parse_graphics_csv
            ;;
        "Audio")
            inxi_parse_audio_csv
            ;;
        "Network")
            inxi_parse_network_csv
            ;;
        "Sensors")
            inxi_parse_sensors_csv
            ;;
        *)
            echo "Item,Value"
            echo "Info,No data available"
            ;;
    esac
}

get_category_summary() {
    local cat_idx="$1"
    local cat_def="${CATEGORIES[$cat_idx]}"
    local cat_name cat_icon cat_section
    IFS='|' read -r cat_name cat_icon cat_section <<< "$cat_def"
    
    # Get first few lines as summary
    local content
    content=$(get_category_content "$cat_idx" | head -5)
    echo "$content"
}

################################################################################
# UI BUILDING FUNCTIONS
################################################################################
build_header() {
    local title="🖥️  System Dashboard"
    local timestamp="$(date '+%H:%M:%S')"
    local mode_indicator
    
    if [[ "$VIEW_MODE" == "overview" ]]; then
        mode_indicator="Overview"
    else
        local cat_def="${CATEGORIES[$CURRENT_CATEGORY]}"
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"
        mode_indicator="$cat_icon $cat_name"
    fi
    
    gum style --border double --border-foreground 39 --width $((TERM_COLS - 4)) \
        --padding "0 1" \
        "$title │ $mode_indicator │ $timestamp"
}

build_nav_panel() {
    local lines=""
    local i=0
    
    lines+="  Categories\n"
    lines+="  ──────────────\n"
    
    for cat_def in "${CATEGORIES[@]}"; do
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"
        
        if [[ $i -eq $CURRENT_CATEGORY ]]; then
            lines+="  ▶ $cat_icon $cat_name\n"
        else
            lines+="    $cat_icon $cat_name\n"
        fi
        ((i++))
    done
    
    # Pad to fill height
    lines+="\n\n\n\n\n\n"
    
    echo -e "$lines" | gum style --border rounded --border-foreground 240 \
        --width 20 --height 22 --padding "0 1"
}

build_overview_panels() {
    # Calculate panel width for 2-column layout
    local total_width=$((TERM_COLS - 26))  # Account for nav panel + margins
    local panel_width=$((total_width / 2 - 2))
    [[ $panel_width -lt 35 ]] && panel_width=35
    
    local panels=()
    local i=0
    
    for cat_def in "${CATEGORIES[@]}"; do
        local cat_name cat_icon
        IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"
        
        # Get one-line summary
        local summary
        summary=$(get_category_summary "$i" 2>/dev/null | tail -n +2 | head -1 | \
            awk -F',' '{if(NF>=2) print substr($0, index($0,$2))}' | cut -c1-$((panel_width - 4)))
        [[ -z "$summary" ]] && summary="Loading..."
        
        local border_color=240
        [[ $i -eq $CURRENT_CATEGORY ]] && border_color=39
        
        # Create compact panel (3 lines: title + summary)
        local panel
        panel=$(printf "%s %s\n%s" "$cat_icon" "$cat_name" "$summary" | \
            gum style --border rounded --border-foreground "$border_color" \
                --width "$panel_width" --height 4 --padding "0 1")
        
        panels+=("$panel")
        ((i++))
    done
    
    # Build 4 rows of 2 panels each
    local row1 row2 row3 row4
    row1=$(gum join --horizontal "${panels[0]}" "${panels[1]}")
    row2=$(gum join --horizontal "${panels[2]}" "${panels[3]}")
    row3=$(gum join --horizontal "${panels[4]}" "${panels[5]}")
    row4=$(gum join --horizontal "${panels[6]}" "${panels[7]}")
    
    gum join --vertical "$row1" "$row2" "$row3" "$row4"
}

build_detail_view() {
    local cat_idx="$1"
    local content_width=$((TERM_COLS - 28))
    
    local cat_def="${CATEGORIES[$cat_idx]}"
    local cat_name cat_icon
    IFS='|' read -r cat_name cat_icon _ <<< "$cat_def"
    
    # Get full content and format it
    local content
    content=$(get_category_content "$cat_idx" 2>/dev/null | tail -n +2 | \
        awk -F',' '{if(NF>=2) printf "  %-20s %s\n", $1":", substr($0, index($0,$2))}')
    [[ -z "$content" ]] && content="  No data available"
    
    echo -e "$cat_icon $cat_name\n──────────────────────────────\n$content" | \
        gum style --border rounded --border-foreground 39 \
            --width "$content_width" --padding "1"
}

build_sensor_bar() {
    local sensor_data
    sensor_data=$(get_sensor_data)
    LAST_SENSOR_UPDATE=$(date '+%H:%M:%S')
    
    # Single line sensor bar
    printf "\e[48;5;236m\e[38;5;245m 🌡️  %s  │  Updated: %s \e[0m" "$sensor_data" "$LAST_SENSOR_UPDATE"
}

build_footer() {
    local help_text
    if [[ "$VIEW_MODE" == "overview" ]]; then
        help_text="↑↓ Navigate │ Enter: Detail │ R: Refresh │ L: Log │ Q: Quit"
    else
        help_text="↑↓ Navigate │ B: Back │ R: Refresh │ L: Log │ Q: Quit"
    fi
    
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
    local nav_panel content_panel
    nav_panel=$(build_nav_panel)
    
    if [[ "$VIEW_MODE" == "overview" ]]; then
        content_panel=$(build_overview_panels)
    else
        content_panel=$(build_detail_view "$CURRENT_CATEGORY")
    fi
    
    # Join nav and content horizontally
    gum join --horizontal "$nav_panel" " " "$content_panel"
    
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

enter_detail() {
    VIEW_MODE="detail"
}

back_to_overview() {
    VIEW_MODE="overview"
}

################################################################################
# SENSOR REFRESH BACKGROUND PROCESS
################################################################################
start_sensor_refresh() {
    # This runs sensor bar updates in background
    # For simplicity, we'll handle this in the main loop with timeouts
    :
}

stop_sensor_refresh() {
    [[ -n "$SENSOR_PID" ]] && kill "$SENSOR_PID" 2>/dev/null
    SENSOR_PID=""
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
                        '[A')  # Up arrow
                            nav_up
                            compose_layout
                            ;;
                        '[B')  # Down arrow
                            nav_down
                            compose_layout
                            ;;
                    esac
                    # Plain Escape - back to overview
                    [[ -z "$key2" ]] && { back_to_overview; compose_layout; }
                    ;;
                '')  # Enter key
                    if [[ "$VIEW_MODE" == "overview" ]]; then
                        enter_detail
                    fi
                    compose_layout
                    ;;
                'b'|'B')
                    back_to_overview
                    compose_layout
                    ;;
                'r'|'R')
                    cursor_show
                    clear
                    gum spin --spinner dot --title "Refreshing system data..." -- \
                        bash -c 'sleep 0.5'
                    refresh_inxi_data
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
            # Timeout - refresh sensor bar in place
            current_time=$(date +%s)
            if [[ $((current_time - last_refresh_time)) -ge $REFRESH_INTERVAL ]]; then
                cursor_save
                cursor_goto $((TERM_ROWS - 2)) 1
                clear_line
                build_sensor_bar
                cursor_restore
                last_refresh_time=$current_time
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
    
    # Initial data collection
    echo ""
    gum style --foreground 39 --bold "🖥️  System Dashboard"
    gum style --foreground 245 "Loading system information..."
    refresh_inxi_data
    
    log_structured info "Dashboard started" terminal "${TERM_COLS}x${TERM_ROWS}"
}

################################################################################
# ENTRY POINT
################################################################################
init_dashboard
main_loop
