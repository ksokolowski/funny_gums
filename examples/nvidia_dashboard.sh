#!/usr/bin/env bash
# nvidia_dashboard.sh - Single-screen NVIDIA GPU + 12VHPWR connector monitor
# Smaller-scope alternative to system_dashboard.sh.
# Left panel: GPU status via nvidia-smi (lib/mod/hw/nvidia.sh).
# Right panel: per-pin 12VHPWR currents/voltages from the astral12vhpwr hwmon
# device exported by astral-hwmon (lib/mod/hw/astral.sh). When the driver is
# not loaded the panel says so — the dashboard still runs, GPU-only.
# shellcheck disable=SC1091,SC2034
set -u

################################################################################
# CONFIGURATION
################################################################################
REFRESH_INTERVAL=1    # Live screen update rate in seconds
MIN_COLS=100          # Minimum terminal width required
MIN_ROWS=22           # Minimum terminal height required
ASTRAL_PANEL_WIDTH=50 # Width of the right 12VHPWR panel

# GPU thresholds (mirror system_dashboard.sh defaults)
TEMP_WARN=70   # GPU temperature warning (°C)
TEMP_CRIT=85   # GPU temperature critical (°C)
UTIL_WARN=80   # GPU utilization warning (%)
UTIL_CRIT=95   # GPU utilization critical (%)
VRAM_WARN=80   # VRAM usage warning (%)
VRAM_CRIT=95   # VRAM usage critical (%)
POWER_WARN=150 # GPU power draw warning (W)
POWER_CRIT=250 # GPU power draw critical (W)
FAN_WARN=70    # Fan speed warning (%)
FAN_CRIT=90    # Fan speed critical (%)

# The right panel's per-pin color judgment uses astral.sh's own thresholds
# (9200/9500 mA per-pin current, 12V -5%/-8%, WireView imbalance rules).

################################################################################
# PATH RESOLUTION (supports symlinks)
################################################################################
_SELF="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf %s "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$_SELF")"
LIB_DIR="$SCRIPT_DIR/../lib"

################################################################################
# SOURCE LIBRARIES
################################################################################
source "$SCRIPT_DIR/../funny_gums.sh"
source "$LIB_DIR/core/sh/gum_wrapper.sh"

# Detect terminal mode for proper emoji width handling
detect_terminal_mode

################################################################################
# COLOR THEME (semantic palette on top of the library NEON_*)
################################################################################
CLR_HEADER=$'\e[1;38;5;39m' # Bold cyan - panel titles
CLR_LABEL=$'\e[38;5;245m'   # Gray - field labels
CLR_VALUE=$'\e[38;5;255m'   # Bright white - values
CLR_GPU=$'\e[38;5;46m'      # Green - GPU values
CLR_GOOD=$'\e[38;5;46m'     # Healthy
CLR_WARN=$'\e[38;5;220m'    # Warning
CLR_CRIT="$NEON_RED"        # Critical
CLR_DIM=$'\e[38;5;242m'     # Dim gray
CLR_BORDER=$'\e[38;5;240m'  # Separators

################################################################################
# STATE VARIABLES
################################################################################
AUTO_REFRESH=true # Toggle with 'a' key
TERM_COLS=0       # Terminal columns
TERM_ROWS=0       # Terminal rows
GPU_PANEL_WIDTH=0 # Derived from terminal width
SENSOR_BAR_ROW=0  # Terminal row where the live bar was drawn
LAST_REFRESH=""

# GPU metrics (from one nvidia-smi batch query)
LIVE_GPU_TEMP=""
LIVE_GPU_UTIL=""
LIVE_GPU_USE_MEM_MIB=""
LIVE_GPU_TOTAL_MEM_MIB=""
LIVE_GPU_POWER=""
LIVE_GPU_FAN=""
LIVE_GPU_CLOCK_CORE=""
LIVE_GPU_CLOCK_MEM=""
LIVE_GPU_NAME=""
LIVE_GPU_DRIVER=""

# 12VHPWR connector metrics (astral12vhpwr hwmon)
read -r -a LIVE_ASTRAL_CURRENTS <<<"" # mA per pin 1..6
read -r -a LIVE_ASTRAL_VOLTAGES <<<"" # mV per pin 1..6
LIVE_ASTRAL_TOTAL_MA=""
LIVE_ASTRAL_MAX_MA=""
LIVE_ASTRAL_BALANCE=""
LIVE_ASTRAL_POWER=""

################################################################################
# DATA COLLECTION
################################################################################
refresh_metrics() {
    LAST_REFRESH=$(date '+%H:%M:%S')

    # One nvidia-smi call for the whole card. nvidia-smi's csv separator is
    # ", " — printf trims the leading space off every field after the first.
    if nvidia_available; then
        local m
        m=$(nvidia_get_metrics)
        if [[ -n "$m" ]]; then
            IFS=',' read -r LIVE_GPU_TEMP LIVE_GPU_UTIL LIVE_GPU_USE_MEM_MIB LIVE_GPU_TOTAL_MEM_MIB \
                LIVE_GPU_POWER LIVE_GPU_FAN LIVE_GPU_CLOCK_CORE LIVE_GPU_CLOCK_MEM \
                LIVE_GPU_NAME LIVE_GPU_DRIVER <<<"$m"
            LIVE_GPU_TEMP=${LIVE_GPU_TEMP# }
            LIVE_GPU_UTIL=${LIVE_GPU_UTIL# }
            LIVE_GPU_USE_MEM_MIB=${LIVE_GPU_USE_MEM_MIB# }
            LIVE_GPU_TOTAL_MEM_MIB=${LIVE_GPU_TOTAL_MEM_MIB# }
            LIVE_GPU_POWER=${LIVE_GPU_POWER# }
            LIVE_GPU_FAN=${LIVE_GPU_FAN# }
            LIVE_GPU_CLOCK_CORE=${LIVE_GPU_CLOCK_CORE# }
            LIVE_GPU_CLOCK_MEM=${LIVE_GPU_CLOCK_MEM# }
            LIVE_GPU_NAME=${LIVE_GPU_NAME# }
            LIVE_GPU_DRIVER=${LIVE_GPU_DRIVER# }
        fi
    fi

    # Per-pin connector frame from the astral-hwmon driver
    if astral_available; then
        local currents voltages
        currents=$(astral_get_all_currents_ma)
        voltages=$(astral_get_all_voltages_mv)
        read -r -a LIVE_ASTRAL_CURRENTS <<<"$currents"
        read -r -a LIVE_ASTRAL_VOLTAGES <<<"$voltages"
        LIVE_ASTRAL_TOTAL_MA=$(astral_get_total_current_ma)
        LIVE_ASTRAL_MAX_MA=$(astral_get_max_current_ma)
        LIVE_ASTRAL_BALANCE=$(astral_get_balance_pct)
        LIVE_ASTRAL_POWER=$(astral_get_connector_power_w)
    else
        read -r -a LIVE_ASTRAL_CURRENTS <<<""
        read -r -a LIVE_ASTRAL_VOLTAGES <<<""
        LIVE_ASTRAL_TOTAL_MA=""
        LIVE_ASTRAL_MAX_MA=""
        LIVE_ASTRAL_BALANCE=""
        LIVE_ASTRAL_POWER=""
    fi
}

# Map a module judgment ("ok"|"warn"|"crit") to a text color.
_status_color() {
    case "$1" in
    crit) printf "%s" "$CLR_CRIT" ;;
    warn) printf "%s" "$CLR_WARN" ;;
    *) printf "%s" "$CLR_GOOD" ;;
    esac
}

check_terminal_size() {
    TERM_COLS=$(tput cols)
    TERM_ROWS=$(tput lines)

    if [[ $TERM_COLS -lt $MIN_COLS ]] || [[ $TERM_ROWS -lt $MIN_ROWS ]]; then
        echo ""
        gum_exec_style --foreground 214 --bold "Terminal too small: ${TERM_COLS}x${TERM_ROWS}"
        echo ""
        gum_exec_style --foreground 245 "This dashboard requires at least ${MIN_COLS}x${MIN_ROWS}."
        echo ""
        exit 1
    fi
}

################################################################################
# PANEL BUILDERS
################################################################################
build_header() {
    local name="${LIVE_GPU_NAME:-GPU}"
    local auto_status
    if [[ "$AUTO_REFRESH" == true ]]; then
        auto_status="${NEON_GREEN}[Auto: ${REFRESH_INTERVAL}s]${RESET}"
    else
        auto_status="${BRIGHT_BLACK}[Auto: OFF]${RESET}"
    fi

    local header_width=$((TERM_COLS - 4))
    local header_text="$EMOJI_GPU  NVIDIA Dashboard │ $name │ $(date '+%H:%M:%S') $auto_status"

    gum_exec_style --border double --border-foreground 51 --width "$header_width" \
        --padding "0 1" "$header_text"
}

build_gpu_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_GPU} Graphics Card${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    if [[ -n "$LIVE_GPU_NAME" ]]; then
        content+="  ${BOLD}${CLR_GPU}${LIVE_GPU_NAME}${RESET}\n"
        content+="  ${CLR_LABEL}Driver:${RESET}   ${CLR_VALUE}${LIVE_GPU_DRIVER}${RESET}\n\n"
    else
        content+="  ${CLR_DIM}No NVIDIA GPU detected${RESET}\n\n"
    fi

    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        content+="  $(ui_temp_gauge "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT" "Temp")\n\n"
    fi

    if [[ -n "$LIVE_GPU_UTIL" ]]; then
        content+="  $(ui_gauge_colored "$LIVE_GPU_UTIL" 100 "$((GPU_PANEL_WIDTH - 24))" "Usage" "$UTIL_WARN" "$UTIL_CRIT")\n\n"
    fi

    if [[ -n "${LIVE_GPU_USE_MEM_MIB:-}" && -n "${LIVE_GPU_TOTAL_MEM_MIB:-}" && "${LIVE_GPU_TOTAL_MEM_MIB:-0}" -gt 0 ]]; then
        local vram_pct used_gi total_gi
        vram_pct=$((LIVE_GPU_USE_MEM_MIB * 100 / LIVE_GPU_TOTAL_MEM_MIB))
        used_gi=$(awk -v m="$LIVE_GPU_USE_MEM_MIB" 'BEGIN { printf "%.1f", m / 1024 }')
        total_gi=$(awk -v m="$LIVE_GPU_TOTAL_MEM_MIB" 'BEGIN { printf "%.1f", m / 1024 }')
        content+="  $(ui_gauge_colored "$vram_pct" 100 "$((GPU_PANEL_WIDTH - 24))" "VRAM" "$VRAM_WARN" "$VRAM_CRIT")\n"
        content+="  ${CLR_LABEL}        ${RESET}${CLR_GPU}${used_gi} GiB${RESET} / ${CLR_DIM}${total_gi} GiB${RESET}\n\n"
    fi

    if [[ -n "$LIVE_GPU_CLOCK_CORE" ]]; then
        content+="  ${CLR_LABEL}Clocks:${RESET}   ${CLR_GPU}${LIVE_GPU_CLOCK_CORE} MHz${RESET} / ${CLR_DIM}${LIVE_GPU_CLOCK_MEM} MHz${RESET}\n"
    fi

    if [[ -n "$LIVE_GPU_POWER" ]]; then
        local power_color="$CLR_GOOD"
        local power_int=${LIVE_GPU_POWER%.*}
        [[ -n "$power_int" && "$power_int" =~ ^[0-9]+$ && "$power_int" -gt "$POWER_WARN" ]] && power_color="$CLR_WARN"
        [[ -n "$power_int" && "$power_int" =~ ^[0-9]+$ && "$power_int" -gt "$POWER_CRIT" ]] && power_color="$CLR_CRIT"
        content+="  ${CLR_LABEL}Power:${RESET}    ${power_color}${LIVE_GPU_POWER} W${RESET}\n"
    fi

    if [[ -n "$LIVE_GPU_FAN" ]]; then
        if [[ "$LIVE_GPU_FAN" =~ ^[0-9]+$ ]]; then
            local fan_color="$CLR_GOOD"
            [[ "$LIVE_GPU_FAN" -gt "$FAN_WARN" ]] && fan_color="$CLR_WARN"
            [[ "$LIVE_GPU_FAN" -gt "$FAN_CRIT" ]] && fan_color="$CLR_CRIT"
            content+="  ${CLR_LABEL}Fan:${RESET}      ${fan_color}${LIVE_GPU_FAN}%${RESET}\n"
        else
            content+="  ${CLR_LABEL}Fan:${RESET}      ${CLR_DIM}${LIVE_GPU_FAN}${RESET}\n"
        fi
    fi

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 46 \
        --width "$GPU_PANEL_WIDTH" --padding "1"
}

build_astral_panel() {
    local content=""

    content+="${CLR_HEADER}${EMOJI_POWER} 12VHPWR Connector (astral-hwmon)${RESET}\n"
    content+="${CLR_BORDER}────────────────────────────────────────${RESET}\n\n"

    if [[ ${#LIVE_ASTRAL_CURRENTS[@]} -eq 0 ]]; then
        content+="  ${CLR_DIM}astral-hwmon driver not loaded${RESET}\n"
        content+="  ${CLR_DIM}No per-pin 12VHPWR sensors.${RESET}\n"
        content+="  ${CLR_DIM}https://github.com/ksokolowski/astral-hwmon${RESET}\n"
    else
        local pin curr_ma volt_mv
        for pin in 1 2 3 4 5 6; do
            curr_ma="${LIVE_ASTRAL_CURRENTS[$((pin - 1))]:-}"
            volt_mv="${LIVE_ASTRAL_VOLTAGES[$((pin - 1))]:-}"
            if [[ -n "$curr_ma" ]]; then
                # Bar shows the load against the 12V-2x6 per-pin rating (9.5 A)
                local pct=$((curr_ma * 100 / _ASTRAL_PIN_CRIT_MA))
                local bar volt_v
                bar=$(ui_minibar "$pct" 8)
                volt_v=$(awk -v mv="$volt_mv" 'BEGIN { printf "%.2f", mv / 1000 }')
                local cur_col volt_col
                cur_col=$(_status_color "$(astral_classify_current_ma "$curr_ma")")
                volt_col=$(_status_color "$(astral_classify_voltage_mv "$volt_mv")")
                content+="  ${CLR_LABEL}P${pin}:${RESET} $bar ${cur_col}${curr_ma} mA${RESET} (${volt_col}${volt_v} V${RESET})\n"
            fi
        done

        content+="  ${CLR_BORDER}────────────────────────────────────────${RESET}\n"
        local cur_col
        cur_col=$(_status_color "$(astral_classify_current_ma "${LIVE_ASTRAL_MAX_MA:-0}")")
        content+="  ${CLR_LABEL}Total:${RESET} ${CLR_VALUE}${LIVE_ASTRAL_TOTAL_MA} mA${RESET}  ${CLR_LABEL}Max:${RESET} ${cur_col}${LIVE_ASTRAL_MAX_MA} mA${RESET}\n"

        if [[ -n "$LIVE_ASTRAL_BALANCE" ]]; then
            local bal_col pow_col total_a
            bal_col=$(_status_color "$(astral_classify_balance_pct "$LIVE_ASTRAL_BALANCE")")
            pow_col=$(_status_color "$(astral_classify_current_ma "${LIVE_ASTRAL_MAX_MA:-0}")")
            total_a=$(awk -v m="${LIVE_ASTRAL_TOTAL_MA:-0}" 'BEGIN { printf "%.2f", m / 1000 }')
            content+="  ${CLR_LABEL}Balance:${RESET} ${bal_col}${LIVE_ASTRAL_BALANCE}%${RESET}  ${CLR_LABEL}Power:${RESET} ${pow_col}${LIVE_ASTRAL_POWER} W${RESET} (${CLR_VALUE}${total_a} A${RESET})\n"
        fi
        content+="  ${CLR_DIM}12V-2x6 per-pin rating: 9.5 A${RESET}\n"
    fi

    echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground 226 \
        --width "$ASTRAL_PANEL_WIDTH" --padding "1"
}

build_sensor_bar() {
    local s=""

    if [[ -n "$LIVE_GPU_TEMP" ]]; then
        local color
        color=$(_ui_threshold_color "$LIVE_GPU_TEMP" "$TEMP_WARN" "$TEMP_CRIT")
        s+="${color}Temp: ${LIVE_GPU_TEMP}°C${RESET}"
    fi
    if [[ -n "$LIVE_GPU_UTIL" ]]; then
        local color
        color=$(_ui_threshold_color "$LIVE_GPU_UTIL" "$UTIL_WARN" "$UTIL_CRIT")
        [[ -n "$s" ]] && s+=" │ "
        s+="${color}Usage: ${LIVE_GPU_UTIL}%${RESET}"
    fi
    if [[ -n "$LIVE_GPU_POWER" ]]; then
        [[ -n "$s" ]] && s+=" │ "
        s+="Power: ${LIVE_GPU_POWER} W"
    fi
    if [[ -n "$LIVE_ASTRAL_TOTAL_MA" ]]; then
        local color
        color=$(_status_color "$(astral_classify_current_ma "${LIVE_ASTRAL_MAX_MA:-0}")")
        [[ -n "$s" ]] && s+=" │ "
        s+="Connector: ${color}${LIVE_ASTRAL_TOTAL_MA} mA${RESET} ${CLR_DIM}(max ${LIVE_ASTRAL_MAX_MA} mA)${RESET}"
    fi

    [[ -z "$s" ]] && s="NVIDIA sensors unavailable"

    s+=" │ Updated: $LAST_REFRESH"

    printf "\e[48;5;236m\e[38;5;245m %s  %b \e[0m" "$EMOJI_TEMP" "$s"
}

build_footer() {
    local help_text="q: Quit │ r: Refresh now │ a: Toggle auto-refresh (${REFRESH_INTERVAL}s)"
    gum_exec_style --foreground 245 --align center "$help_text"
}

################################################################################
# LAYOUT COMPOSER
################################################################################

# Count the terminal rows a captured block occupies once re-printed as
# `printf '%s\n' "$block"` (see compose_layout below for the reasoning).
_count_layout_lines() {
    local s="$1"
    [[ -z "$s" ]] && {
        echo 0
        return
    }
    echo $(($(printf '%s' "$s" | wc -l) + 1))
}

compose_layout() {
    local layout_row=0

    # Header
    local header
    header=$(build_header)
    printf '%s\n' "$header"
    ((layout_row += $(_count_layout_lines "$header")))
    printf '\n'
    ((layout_row++))

    # Main content: GPU panel left, 12VHPWR panel right
    local gpu_panel astral_panel joined
    gpu_panel=$(build_gpu_panel)
    astral_panel=$(build_astral_panel)
    joined=$(gum join --horizontal "$gpu_panel" " " "$astral_panel")
    printf '%s\n' "$joined"
    ((layout_row += $(_count_layout_lines "$joined")))
    printf '\n'
    ((layout_row++))

    # Sensor bar
    SENSOR_BAR_ROW=$((layout_row + 1))
    build_sensor_bar
    printf '\n'

    # Footer
    build_footer
}

################################################################################
# INITIALIZATION & MAIN LOOP
################################################################################
toggle_auto_refresh() {
    if [[ "$AUTO_REFRESH" == true ]]; then
        AUTO_REFRESH=false
        log_structured info "Auto-refresh disabled"
    else
        AUTO_REFRESH=true
        log_structured info "Auto-refresh enabled"
    fi
}

main_loop() {
    local key last_refresh_time current_time
    last_refresh_time=$(date +%s)

    cursor_hide
    trap 'cursor_show; exit 0' EXIT INT TERM

    clear
    compose_layout

    while true; do
        # Non-blocking read with timeout; timeout drives the live refresh
        if read -rsn1 -t "$REFRESH_INTERVAL" key; then
            case "$key" in
            'a' | 'A')
                toggle_auto_refresh
                compose_layout
                ;;
            'r' | 'R')
                refresh_metrics
                compose_layout
                ;;
            'q' | 'Q')
                cursor_show
                gum_exec_style --foreground 51 "Goodbye!"
                exit 0
                ;;
            esac
        else
            if [[ "$AUTO_REFRESH" == true ]]; then
                # Update terminal dimensions in case of resize
                TERM_ROWS=$(tput lines)
                TERM_COLS=$(tput cols)
                GPU_PANEL_WIDTH=$((TERM_COLS - ASTRAL_PANEL_WIDTH - 9))

                current_time=$(date +%s)
                if [[ $((current_time - last_refresh_time)) -ge $REFRESH_INTERVAL ]]; then
                    refresh_metrics
                    # In-place full redraw: overwrite from the top, no clear,
                    # so the screen does not flicker each second.
                    cursor_goto 1 1
                    compose_layout
                    clear_to_end
                    last_refresh_time=$current_time
                fi
            fi
        fi
    done
}

init_dashboard() {
    LOG_FILE="/tmp/nvidia_dashboard_$(date +%Y-%m-%d_%H-%M-%S).log"
    log_init "$LOG_FILE"

    check_dependencies
    check_terminal_size
    GPU_PANEL_WIDTH=$((TERM_COLS - ASTRAL_PANEL_WIDTH - 9))

    echo ""
    gum_exec_style --foreground 51 --bold "$EMOJI_GPU  NVIDIA Dashboard"
    gum_exec_style --foreground 245 "Reading GPU and 12VHPWR sensors..."

    refresh_metrics

    log_structured info "Dashboard started" terminal "${TERM_COLS}x${TERM_ROWS}" auto_refresh "$AUTO_REFRESH"
}

################################################################################
# ENTRY POINT
################################################################################
init_dashboard
main_loop
