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
DASHBOARD_TITLE_ICON="🔧" # Prefixed before the title; pass "" to suppress.
DASHBOARD_COMPLETED=0
DASHBOARD_RUNNING=-1
DASHBOARD_HAS_FAILURE=false
DASHBOARD_PROGRESS_WIDTH=30
DASHBOARD_QUIET=false
DASHBOARD_SPINNER="DOTS"
# Frame padding (top/bottom = ROWS, left/right = COLS) passed to gum --padding.
# steps_start (line offset of first step row inside the frame) and the spinner
# glyph column are derived from these — change them here and the redraw
# arithmetic follows automatically.
DASHBOARD_PADDING_TOP=1
DASHBOARD_PADDING_LEFT=2
# Track whether dashboard_init was the one that set LOGGING_QUIET, so
# dashboard_cleanup only resets it if we own the toggle (avoids stomping
# on a caller that set the flag themselves around their own TUI).
_DASHBOARD_OWNS_LOGGING_QUIET=false

# 1-indexed row of the first step inside the gum-styled frame, derived from
# padding. Layout above the steps: 1 top-border + DASHBOARD_PADDING_TOP
# padding-rows + 1 title-row + 1 blank-separator (from "\n\n" after title)
# = PT+3 rows above, so the first step lands on row PT+4.
_dashboard_steps_start() {
    echo $((4 + DASHBOARD_PADDING_TOP))
}

# Column of the spinner glyph (first content cell of a step row). Layout:
# 1 left-border cell + DASHBOARD_PADDING_LEFT padding cells + the glyph at
# the next column → column 2 + DASHBOARD_PADDING_LEFT.
_dashboard_spinner_col() {
    echo $((2 + DASHBOARD_PADDING_LEFT))
}
DASHBOARD_BORDER_COLOR="6"
DASHBOARD_PROGRESS_COLOR="${CYAN}"
DASHBOARD_WIDTH="" # Frame width (empty = auto)

# Initialize dashboard with title (and optional icon prefix).
# Usage: dashboard_init "My Dashboard Title"           # uses default 🔧 icon
#        dashboard_init "My Title" "🚀"                # custom icon
#        dashboard_init "My Title" ""                  # no icon prefix
dashboard_init() {
    DASHBOARD_TITLE="${1:-Dashboard}"
    # Use the 2-arg form ${var-default} (no colon) so passing an explicit
    # empty string overrides; only an unset $2 falls back to the wrench.
    DASHBOARD_TITLE_ICON="${2-🔧}"
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

    # We own the screen now — silence log_* tee-to-stdout so per-step log
    # lines don't desync the dashboard's cursor accounting.
    # See LOGGING_QUIET in lib/core/sh/logging.sh.
    if [[ "${LOGGING_QUIET:-false}" != "true" ]]; then
        LOGGING_QUIET=true
        _DASHBOARD_OWNS_LOGGING_QUIET=true
    fi
}

# Release the terminal: restore logging behaviour to whatever it was before
# dashboard_init. Safe to call even if dashboard_init wasn't (no-op then).
# Recommended: add to your EXIT trap alongside cursor_show / runner_cleanup.
dashboard_cleanup() {
    if [[ "$_DASHBOARD_OWNS_LOGGING_QUIET" == "true" ]]; then
        LOGGING_QUIET=false
        _DASHBOARD_OWNS_LOGGING_QUIET=false
    fi
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
    if [[ -n "$DASHBOARD_TITLE_ICON" ]]; then
        content+="${CYAN}${DASHBOARD_TITLE_ICON} ${DASHBOARD_TITLE}${RESET}\n\n"
    else
        content+="${CYAN}${DASHBOARD_TITLE}${RESET}\n\n"
    fi

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
    output=$(echo -e "$content" | gum_exec_style --no-strip-ansi --border rounded --border-foreground "$DASHBOARD_BORDER_COLOR" --padding "$DASHBOARD_PADDING_TOP $DASHBOARD_PADDING_LEFT" --align left $width_arg)
    printf '%s\n' "$output"

    DASHBOARD_LINES=$(printf '%s\n' "$output" | wc -l)

    # Calculate line offsets (steps_start derived from current padding)
    local steps_start
    steps_start=$(_dashboard_steps_start)
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
    local col
    col=$(_dashboard_spinner_col)

    # Restore, move up `line_offset` rows, place cursor at the derived column,
    # print, restore.
    printf '\e8\e[%dA\e[%dG%s\e8' "$line_offset" "$col" "$spinner_char"
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
