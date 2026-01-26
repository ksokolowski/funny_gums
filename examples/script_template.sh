#!/usr/bin/env bash
# script_template.sh - Reusable template for interactive scripts
# Copy this file and customize for your own scripts
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
source "$LIB_DIR/core/terminal.sh"
source "$LIB_DIR/core/text.sh"
source "$LIB_DIR/core/emojis.sh"
source "$LIB_DIR/ui/ui.sh"
source "$LIB_DIR/dashboard/dashboard.sh"
source "$LIB_DIR/dashboard/runner.sh"

# Detect terminal mode for VS16 emoji support
detect_terminal_mode

############################
# CUSTOMIZATION - Edit these!
############################
# Script metadata
SCRIPT_NAME="My Awesome Script"
SCRIPT_VERSION="1.0"
SCRIPT_ICON="🚀"

# Color theme (pick your colors!)
# Available: NEON_CYAN, NEON_GREEN, NEON_PINK, NEON_PURPLE, NEON_YELLOW, NEON_RED
THEME_PRIMARY="$NEON_CYAN"
THEME_PRIMARY_NUM="$NEON_CYAN_NUM"
THEME_SECONDARY="$NEON_GREEN"
THEME_ACCENT="$NEON_PINK"

# UI Layout - unified frame width for visual consistency
FRAME_WIDTH=60

# Logging
LOG_FILE="/tmp/${SCRIPT_NAME// /_}_$(date +%Y-%m-%d_%H-%M-%S).log"
log_init "$LOG_FILE"

# Dashboard styling
DASHBOARD_SPINNER="DOTS"  # Options: DOTS, CIRCLE, BRAILLE, GLOBE, MOON, CLOCK, ARROWS, BOUNCE, RGB

############################
# STEP DEFINITIONS
# Define your steps here!
############################
# Icons for categories (customize as needed)
# Use emoji variables for proper VS16 handling across terminals
declare -A CATEGORY_ICON=(
    [setup]="$EMOJI_CPU"
    [process]="$EMOJI_PROCESS"
    [network]="$EMOJI_NETWORK"
    [files]="$EMOJI_FILES"
    [done]="$EMOJI_DONE"
)

# Step definitions: "category|description"
STEP_DEFS=(
    "setup|Initialize environment"
    "process|Process data files"
    "network|Fetch remote resources"
    "files|Clean up temporary files"
    "done|Finalize and report"
)

# Commands for each step (must match STEP_DEFS order)
# Replace these with your actual commands!
STEP_CMDS=(
    "sleep 1"                              # Step 0: dummy init
    "sleep 1.5"                            # Step 1: dummy process
    "sleep 0.8"                            # Step 2: dummy network
    "sleep 0.5"                            # Step 3: dummy cleanup
    "sleep 0.3"                            # Step 4: dummy finalize
)

############################
# CLEANUP HANDLER
############################
cleanup() {
    cursor_show
    runner_cleanup
}
trap cleanup EXIT

############################
# WELCOME SCREEN
############################
show_welcome() {
    echo ""
    ui_box_double --width "$FRAME_WIDTH" --padding "1 5" --border-foreground "$THEME_PRIMARY_NUM" \
        "${THEME_PRIMARY}${BOLD}${SCRIPT_ICON} ${SCRIPT_NAME} ${THEME_ACCENT}v${SCRIPT_VERSION}${RESET}" \
        "" \
        "This script will:" \
        "  ${THEME_SECONDARY}•${RESET} Initialize the environment" \
        "  ${THEME_SECONDARY}•${RESET} Process your data" \
        "  ${THEME_SECONDARY}•${RESET} Clean up when done" \
        "" \
        "${DIM}Customize this welcome message for your script!${RESET}"
    echo ""
}

############################
# STEP SELECTION (Optional)
############################
select_steps() {
    if ui_confirm "Do you want to select which steps to run?" --default=false; then
        echo ""

        # Pre-select all steps
        local preselected
        preselected=$(IFS=,; echo "${DASHBOARD_STEPS[*]}")

        local selected
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
    local enabled_count
    enabled_count=$(dashboard_enabled_count)
    if ((enabled_count == 0)); then
        ui_info "No steps selected. Exiting."
        exit 0
    fi
}

############################
# MAIN EXECUTION
############################
main() {
    # 1. Show welcome screen
    show_welcome

    # 2. Ask for confirmation
    if ! ui_confirm "Do you want to proceed?"; then
        ui_info "Cancelled by user."
        exit 0
    fi

    # 3. Initialize dashboard
    DASHBOARD_BORDER_COLOR="$THEME_PRIMARY_NUM"
    DASHBOARD_PROGRESS_COLOR="$THEME_SECONDARY"
    DASHBOARD_WIDTH="$FRAME_WIDTH"
    dashboard_init "${SCRIPT_ICON} ${SCRIPT_NAME}"

    # 4. Add steps to dashboard
    for i in "${!STEP_DEFS[@]}"; do
        IFS='|' read -r category title <<< "${STEP_DEFS[$i]}"
        dashboard_add_step "${CATEGORY_ICON[$category]} $title"
    done

    # 5. Optional: Let user select steps
    echo ""
    select_steps

    # 6. Run the dashboard
    log_silent "Starting ${SCRIPT_NAME}..."

    echo ""
    cursor_hide
    dashboard_draw

    # 7. Execute each step
    for i in "${!STEP_CMDS[@]}"; do
        # shellcheck disable=SC2086
        runner_exec "$i" ${STEP_CMDS[$i]}
    done

    cursor_show

    # 8. Show summary
    echo ""
    local has_failure=false
    if dashboard_has_failure; then
        has_failure=true
        ui_error --width "$FRAME_WIDTH" --padding "1 5" --border-foreground "$NEON_RED_NUM" \
            "❌ Some steps failed" \
            "" \
            "${DIM}Log file: ${LOG_FILE}${RESET}"
    else
        ui_success --width "$FRAME_WIDTH" --padding "1 5" --border-foreground "$NEON_GREEN_NUM" \
            "${THEME_SECONDARY}${BOLD}✨ All done!${RESET}" \
            "" \
            "${DIM}${SCRIPT_NAME} completed successfully${RESET}"
        log_silent "All tasks completed successfully"
    fi

    # 9. Offer to view log (default=yes on error, default=no on success)
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
}

# Run main
main "$@"
