#!/usr/bin/env bash
# shellcheck disable=SC1091
set -u

############################
# SCRIPT CONFIGURATION
############################
# Resolve symlinks to get actual script directory
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source shared functions
source "$LIB_DIR/core/colors.sh"
source "$LIB_DIR/core/cursor.sh"
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/core/spinner.sh"
source "$LIB_DIR/core/sudo.sh"
source "$LIB_DIR/core/terminal.sh"
source "$LIB_DIR/core/text.sh"
source "$LIB_DIR/core/emojis.sh"
source "$LIB_DIR/ui/ui.sh"
source "$LIB_DIR/dashboard/dashboard.sh"
source "$LIB_DIR/dashboard/runner.sh"

# Detect terminal mode for VS16 emoji support
detect_terminal_mode

# Ensure gum version requirement is met
ui_version_check ">=0.17.0" || exit 1

############################
# DEFAULTS
############################
DISK_DEV="/dev/sda"
RGB_DEV=2
RGB_EFFECT="rainbow"
export VERBOSE=false
LOG_FILE="/tmp/openrgb_fix_$(date +%Y-%m-%d_%H-%M-%S).log"
log_init "$LOG_FILE"

# UI Layout - unified frame width for visual consistency
FRAME_WIDTH=60

# Dashboard styling
DASHBOARD_SPINNER="MOON"

############################
# STEP DEFINITIONS
############################
# Use emoji variables for proper VS16 handling across terminals
declare -A CATEGORY_ICON=(
    [disk]="$EMOJI_DISK"
    [service]="$EMOJI_CPU"
    [rgb]="$EMOJI_RGB"
    [package]="$EMOJI_PACKAGE"
)

# Use indexed arrays to preserve order
STEP_DEFS=(
    "disk|Spin down disk $DISK_DEV"
    "service|Stop OpenLinkHub.service"
    "rgb|Init OpenRGB device $RGB_DEV ($RGB_EFFECT)"
    "service|Start OpenLinkHub.service"
    "package|apt update"
    "package|apt dist-upgrade"
    "package|snap refresh"
    "package|flatpak update"
)

# Commands for each step (indexed array)
STEP_CMDS=(
    "sudo hdparm -y $DISK_DEV"
    "sudo systemctl stop OpenLinkHub.service"
    "/usr/bin/openrgb -d $RGB_DEV -m $RGB_EFFECT"
    "sudo systemctl start OpenLinkHub.service"
    "sudo apt update"
    "sudo apt dist-upgrade -y"
    "sudo snap refresh"
    "flatpak update -y"
)

############################
# CLEANUP
############################
cleanup() {
    cursor_show
    runner_cleanup
    sudo_cleanup
}
trap cleanup EXIT

############################
# STARTUP CONFIRMATION
############################
echo ""
ui_box_double --width "$FRAME_WIDTH" --padding "1 3" --border-foreground "$NEON_PINK_NUM" \
    "${NEON_CYAN}${BOLD}🔧 OpenRGB / OpenLinkHub Fix Script ${NEON_PINK}v2.0${RESET}" \
    "" \
    "This script will:" \
    "  • ${NEON_YELLOW}Spin down disk${RESET} and restart ${BOLD}OpenLinkHub${RESET} ⚡" \
    "  • ${NEON_GREEN}Initialize RGB devices${RESET} via ${BOLD}OpenRGB${RESET} 🌈" \
    "  • ${NEON_PURPLE}Update system packages${RESET} (*apt, snap, flatpak*) 📦" \
    "" \
    "🚨 ${NEON_RED}${BOLD}Requires sudo privileges${RESET}"

echo ""
if ! ui_confirm "Do you want to proceed?"; then
    ui_info "Cancelled by user."
    exit 0
fi

# Initialize dashboard
DASHBOARD_BORDER_COLOR="$NEON_CYAN_NUM"
DASHBOARD_PROGRESS_COLOR="$NEON_CYAN"
DASHBOARD_WIDTH="$FRAME_WIDTH"
dashboard_init "$(ui_format_template "{{ Bold \"${NEON_CYAN}OpenRGB${RESET} / ${NEON_PINK}OpenLinkHub${RESET} Dashboard\" }}")"

# Add steps to dashboard
for i in "${!STEP_DEFS[@]}"; do
    IFS='|' read -r category title <<< "${STEP_DEFS[$i]}"
    dashboard_add_step "${CATEGORY_ICON[$category]} $title"
done

############################
# STEP SELECTION
############################
echo ""
if ui_confirm "Do you want to select which steps to run?" --default=false; then
    echo ""

    # Build selection list
    choices=""
    for i in "${!DASHBOARD_STEPS[@]}"; do
        choices+="${DASHBOARD_STEPS[$i]}"$'\n'
    done
    choices=$(echo -n "$choices" | head -c -1)

    # Pre-select all steps
    preselected=$(IFS=,; echo "${DASHBOARD_STEPS[*]}")

    selected=$(ui_choose_multi "${DASHBOARD_STEPS[@]}" \
        --selected="$preselected" \
        --header "Select steps to run (Space to toggle, Enter to confirm):" \
        --height 12)

    # Disable unselected steps
    for i in "${!DASHBOARD_STEPS[@]}"; do
        if ! echo "$selected" | grep -qF "${DASHBOARD_STEPS[$i]}"; then
            dashboard_enable_step "$i" false
        fi
    done
fi

# Check if any steps selected
enabled_count=$(dashboard_enabled_count)
if ((enabled_count == 0)); then
    ui_info "No steps selected. Exiting."
    exit 0
fi

############################
# SUDO AUTHENTICATION
############################
SUDO_FRAME_WIDTH="$FRAME_WIDTH"
# shellcheck disable=SC2119
if ! sudo_setup_styled; then
    ui_error --padding "1 5" "Failed to authenticate sudo."
    exit 1
fi

log_silent "Sudo authenticated. Starting tasks..." user "$USER"

############################
# MAIN EXECUTION
############################
cursor_hide
dashboard_draw

# Execute each step
for i in "${!STEP_CMDS[@]}"; do
    # shellcheck disable=SC2086 # Word splitting intentional for command args
    runner_exec "$i" ${STEP_CMDS[$i]}
done

cursor_show

############################
# FINAL SUMMARY
############################
echo ""
has_failure=false
if dashboard_has_failure; then
    has_failure=true
    ui_error --width "$FRAME_WIDTH" --padding "1 3" --border-foreground "$NEON_RED_NUM" \
        "❌ Some steps failed" \
        "" \
        "${DIM}Log file: ${LOG_FILE}${RESET}"
else
    ui_success --width "$FRAME_WIDTH" --padding "1 3" --border-foreground "$NEON_GREEN_NUM" \
        "✨ $(ui_format_template "{{ Bold \"${NEON_GREEN}Done.${RESET} System & ${NEON_CYAN}RGB${RESET} state are clean ✨\" }}")"
    log_silent "All tasks completed successfully"
fi

# Offer to view log (default=yes on error, default=no on success)
echo ""
if $has_failure; then
    if ui_confirm "View log file?" --affirmative "Yes" --negative "No"; then
        echo ""
        ui_box --width "$FRAME_WIDTH" --padding "0 2" "📋 Log: $LOG_FILE"
        echo ""
        ui_pager_numbered < "$LOG_FILE"
    fi
else
    if ui_confirm "View log file?" --affirmative "Yes" --negative "No" --default=false; then
        echo ""
        ui_box --width "$FRAME_WIDTH" --padding "0 2" "📋 Log: $LOG_FILE"
        echo ""
        ui_pager_numbered < "$LOG_FILE"
    fi
fi
