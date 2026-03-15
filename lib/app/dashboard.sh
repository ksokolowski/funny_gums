#!/usr/bin/env bash
# dashboard.sh - Dashboard drawing functions with progress tracking
# Source this file for step-based dashboard UI
# shellcheck disable=SC1091

# Prevent multiple sourcing
[[ -n "${_DASHBOARD_SH_LOADED:-}" ]] && return 0
_DASHBOARD_SH_LOADED=1

# Source dependencies
_DASHBOARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DASHBOARD_DIR/../core/term/colors.sh"
source "$_DASHBOARD_DIR/../core/term/cursor.sh"
source "$_DASHBOARD_DIR/../ui/widgets/spinner.sh"
source "$_DASHBOARD_DIR/../core/text/text.sh"
source "$_DASHBOARD_DIR/../core/sh/gum_wrapper.sh"

# Dashboard state
declare -a DASHBOARD_STEPS=()       # Step display names
declare -a DASHBOARD_STATUS=()      # Step status icons
declare -a DASHBOARD_ENABLED=()     # Step enabled flags
declare -A DASHBOARD_LINE_OFFSET=() # Line offsets for spinner updates
DASHBOARD_LINES=0
DASHBOARD_TITLE=""
DASHBOARD_COMPLETED=0
DASHBOARD_RUNNING=-1
DASHBOARD_HAS_FAILURE=false
DASHBOARD_PROGRESS_WIDTH=30
DASHBOARD_QUIET=false
DASHBOARD_SPINNER="DOTS"
DASHBOARD_BORDER_COLOR="6"
DASHBOARD_PROGRESS_COLOR="${CYAN}"
DASHBOARD_WIDTH="" # Frame width (empty = auto)

# Initialize dashboard with title
# Usage: dashboard_init "My Dashboard Title"
dashboard_init() {
    DASHBOARD_TITLE="${1:-Dashboard}"
    DASHBOARD_STEPS=()
    DASHBOARD_STATUS=()
    DASHBOARD_ENABLED=()
    DASHBOARD_LINE_OFFSET=()
    DASHBOARD_LINES=0
    DASHBOARD_COMPLETED=0
    DASHBOARD_RUNNING=-1
    DASHBOARD_HAS_FAILURE=false
    spinner_set "$DASHBOARD_SPINNER"
    DASHBOARD_BORDER_COLOR="${DASHBOARD_BORDER_COLOR:-6}"
    DASHBOARD_PROGRESS_COLOR="${DASHBOARD_PROGRESS_COLOR:-${CYAN}}"
}

# Add a step to the dashboard
# Usage: dashboard_add_step "💾 Step description"
dashboard_add_step() {
    local idx=${#DASHBOARD_STEPS[@]}
    DASHBOARD_STEPS+=("$1")
    DASHBOARD_STATUS+=("⬜")
    DASHBOARD_ENABLED+=(true)
}

# Enable/disable a step
# Usage: dashboard_enable_step 0 true|false
dashboard_enable_step() {
    local idx=$1
    local enabled=${2:-true}
    DASHBOARD_ENABLED[idx]=$enabled
}

# Get enabled step count
dashboard_enabled_count() {
    local count=0
    for enabled in "${DASHBOARD_ENABLED[@]}"; do
        [[ "$enabled" == "true" ]] && ((count++))
    done
    echo "$count"
}

# Draw the dashboard
dashboard_draw() {
    [[ "$DASHBOARD_QUIET" == "true" ]] && return

    local enabled_count=0
    for enabled in "${DASHBOARD_ENABLED[@]}"; do
        [[ "$enabled" == "true" ]] && ((enabled_count++))
    done

    # Clear previous dashboard
    if ((DASHBOARD_LINES > 0)); then
        cursor_up "$DASHBOARD_LINES"
        clear_to_end
    fi

    # Build content
    local content=""
    content+="${CYAN}🔧 ${DASHBOARD_TITLE}${RESET}\n\n"

    for i in "${!DASHBOARD_STEPS[@]}"; do
        if [[ "${DASHBOARD_ENABLED[$i]}" != "true" ]]; then
            # Skipped: dim text with skip icon
            content+="${DIM}⏩ ${DASHBOARD_STEPS[i]}${RESET}\n"
        elif ((DASHBOARD_RUNNING == i)); then
            local spinner_char
            spinner_frame_ref spinner_char
            content+="${spinner_char} ${DASHBOARD_STEPS[i]}${RESET}\n"
        else
            content+="${CYAN}${DASHBOARD_STATUS[i]} ${DASHBOARD_STEPS[i]}${RESET}\n"
        fi
    done

    # Progress bar
    local pct_denom=$((enabled_count > 0 ? enabled_count : 1))
    local filled=$((DASHBOARD_COMPLETED * DASHBOARD_PROGRESS_WIDTH / pct_denom))
    local empty=$((DASHBOARD_PROGRESS_WIDTH - filled))
    local bar=""
    for ((j = 0; j < filled; j++)); do bar+="█"; done
    for ((j = 0; j < empty; j++)); do bar+="░"; done
    local percent=$((DASHBOARD_COMPLETED * 100 / pct_denom))
    content+="\n${DASHBOARD_PROGRESS_COLOR}⏳ Progress [${bar}] ${percent}%${RESET}"

    # Display in gum frame
    local output width_arg=""
    [[ -n "$DASHBOARD_WIDTH" ]] && width_arg="--width $DASHBOARD_WIDTH"

    # Note: VS16 stripping for VTE terminals is handled globally in emojis.sh

    # shellcheck disable=SC2086
    output=$(echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground "$DASHBOARD_BORDER_COLOR" --padding "1 2" --align left $width_arg)
    printf '%s\n' "$output"

    DASHBOARD_LINES=$(printf '%s\n' "$output" | wc -l)

    # Calculate line offsets
    local steps_start=5
    for i in "${!DASHBOARD_STEPS[@]}"; do
        DASHBOARD_LINE_OFFSET[$i]=$((DASHBOARD_LINES + 1 - steps_start - i))
    done

    # Save cursor position
    cursor_save
}

# Update spinner in place (no full redraw)
dashboard_update_spinner() {
    [[ "$DASHBOARD_QUIET" == "true" ]] && return
    ((DASHBOARD_RUNNING < 0)) && return

    local idx=$DASHBOARD_RUNNING
    local spinner_char
    spinner_frame_ref spinner_char
    local line_offset="${DASHBOARD_LINE_OFFSET[$idx]}"

    # Restore, move up, print, restore
    printf '\e8\e[%dA\e[4G%s\e8' "$line_offset" "$spinner_char"
}

# Mark step as running
# Usage: dashboard_step_start 0
dashboard_step_start() {
    DASHBOARD_RUNNING=$1
    spinner_reset
    dashboard_draw
}

# Mark step as completed
# Usage: dashboard_step_done 0 [success=true]
dashboard_step_done() {
    local idx=$1
    local success=${2:-true}

    if [[ "$success" == "true" ]]; then
        DASHBOARD_STATUS[idx]="✅"
    else
        DASHBOARD_STATUS[idx]="❌"
        DASHBOARD_HAS_FAILURE=true
    fi

    ((DASHBOARD_COMPLETED++))
    DASHBOARD_RUNNING=-1
    dashboard_draw
}

# Mark step as skipped
# Usage: dashboard_step_skip 0
dashboard_step_skip() {
    local idx=$1
    DASHBOARD_STATUS[idx]="⏩"
    DASHBOARD_ENABLED[idx]=false
}

# Check if any step failed
dashboard_has_failure() {
    [[ "$DASHBOARD_HAS_FAILURE" == "true" ]]
}
