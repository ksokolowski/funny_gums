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
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/cursor.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/spinner.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/sudo.sh"
source "$LIB_DIR/dashboard.sh"
source "$LIB_DIR/runner.sh"

############################
# DEFAULTS
############################
DISK_DEV="/dev/sda"
RGB_DEV=2
RGB_EFFECT="rainbow"
export VERBOSE=false
LOG_FILE="/tmp/openrgb_fix.log"
log_init "$LOG_FILE"

############################
# STEP DEFINITIONS
############################
declare -A CATEGORY_ICON=(
    [disk]="💾"
    [service]="🔌"
    [rgb]="🎨"
    [package]="📦"
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
ui_box_double \
    "🔧 OpenRGB / OpenLinkHub Fix Script" \
    "" \
    "This script will:" \
    "  • Spin down disk and restart OpenLinkHub" \
    "  • Initialize RGB devices via OpenRGB" \
    "  • Update system packages (apt, snap, flatpak)" \
    "" \
    "🚨 Requires sudo privileges"

echo ""
if ! ui_confirm "Do you want to proceed?"; then
    ui_info "Cancelled by user."
    exit 0
fi

############################
# INITIALIZE DASHBOARD
############################
dashboard_init "OpenRGB / OpenLinkHub Dashboard"

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

    selected=$(echo "$choices" | gum choose --no-limit --height 12 \
        --header "Select steps to run (Space to toggle, Enter to confirm):" \
        --selected="$preselected")

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
echo ""
log_info "Authenticating sudo credentials..."

# shellcheck disable=SC2119
if ! sudo_setup; then
    ui_error "Failed to authenticate sudo."
    exit 1
fi

log_info "Sudo authenticated. Starting tasks..."
sleep 1

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
if dashboard_has_failure; then
    ui_error "${RED}❌ Some steps failed${RESET}"
    echo ""
    log_error "Displaying error log..."
    echo ""
    log_show
else
    ui_success "${GREEN}✨ Done. System & RGB state are clean ✨${RESET}"
    log_info "All tasks completed successfully"
fi
