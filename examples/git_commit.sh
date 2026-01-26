#!/usr/bin/env bash
# git_commit.sh - Interactive conventional commit helper
# Demonstrates: ui_choose, ui_input, ui_write, ui_confirm, ui_format_emoji
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
source "$LIB_DIR/core/colors.sh"
source "$LIB_DIR/core/terminal.sh"
source "$LIB_DIR/core/text.sh"
source "$LIB_DIR/core/emojis.sh"
source "$LIB_DIR/ui/ui.sh"

# Detect terminal mode for VS16 emoji support
detect_terminal_mode

############################
# COMMIT TYPES
# VS16 emojis (♻️, ⚙️) are now supported with proper width handling
############################
COMMIT_TYPES=(
    "feat     ✨ A new feature"
    "fix      🐛 A bug fix"
    "docs     📚 Documentation only changes"
    "style    💎 Code style (formatting, semicolons, etc)"
    "refactor $EMOJI_RECYCLE  Code refactoring"
    "perf     ⚡ Performance improvement"
    "test     🧪 Adding or updating tests"
    "build    📦 Build system or dependencies"
    "ci       🤖 CI/CD configuration"
    "chore    $EMOJI_CPU Other changes (maintenance)"
    "revert   ⏪ Revert a previous commit"
)

############################
# MAIN
############################
echo ""
ui_box "🔨 Conventional Commit Helper" \
    "" \
    "Create a well-formatted commit message following" \
    "the Conventional Commits specification."

echo ""

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ui_error "Not a git repository!"
    exit 1
fi

# Check for staged changes
if git diff --cached --quiet; then
    ui_warn "No staged changes found!"
    echo ""
    if ! ui_confirm "Continue anyway?"; then
        exit 0
    fi
fi

# Step 1: Select commit type
echo ""
ui_info "Step 1: Select commit type"
type_line=$(ui_choose_with_header "Choose commit type:" "${COMMIT_TYPES[@]}")
if [[ -z "$type_line" ]]; then
    ui_info "Cancelled."
    exit 0
fi
commit_type=$(echo "$type_line" | awk '{print $1}')
echo "  Selected: ${GREEN}$commit_type${RESET}"

# Step 2: Enter scope (optional)
echo ""
ui_info "Step 2: Enter scope (optional, e.g., api, ui, core)"
scope=$(ui_input "component name (optional)")
if [[ -n "$scope" ]]; then
    echo "  Scope: ${GREEN}$scope${RESET}"
else
    echo "  Scope: ${DIM}(none)${RESET}"
fi

# Step 3: Enter short description
echo ""
ui_info "Step 3: Enter short description (max 50 chars)"
description=$(ui_input "short description of change")
if [[ -z "$description" ]]; then
    ui_error "Description is required!"
    exit 1
fi
echo "  Description: ${GREEN}$description${RESET}"

# Step 4: Enter body (optional)
echo ""
ui_info "Step 4: Enter detailed body (optional, Ctrl+D to finish)"
if ui_confirm "Add detailed body?" --default=false; then
    body=$(ui_write "Detailed explanation of the change...")
else
    body=""
fi

# Step 5: Breaking change?
echo ""
breaking=""
if ui_confirm "Is this a BREAKING CHANGE?" --default=false; then
    breaking=$(ui_input "Describe the breaking change")
fi

# Step 6: Issue reference (optional)
echo ""
ui_info "Step 6: Reference issues (optional)"
issues=$(ui_input "e.g., Closes #123, Fixes #456")

############################
# BUILD COMMIT MESSAGE
############################
# Header: type(scope): description
if [[ -n "$scope" ]]; then
    header="${commit_type}(${scope}): ${description}"
else
    header="${commit_type}: ${description}"
fi

# Full message
commit_msg="$header"

if [[ -n "$body" ]]; then
    commit_msg+="\n\n$body"
fi

if [[ -n "$breaking" ]]; then
    commit_msg+="\n\nBREAKING CHANGE: $breaking"
fi

if [[ -n "$issues" ]]; then
    commit_msg+="\n\n$issues"
fi

############################
# PREVIEW AND CONFIRM
############################
echo ""
ui_box "📝 Commit Message Preview" "" "$(echo -e "$commit_msg")"

echo ""
if ui_confirm "Create this commit?"; then
    echo -e "$commit_msg" | git commit -F -
    ui_success "✅ Commit created successfully!"
else
    ui_info "Commit cancelled."
fi
