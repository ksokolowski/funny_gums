#!/usr/bin/env bash
# check_deps.sh - Verify project dependencies
# Usage: ./scripts/check_deps.sh

set -uo pipefail

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RESET=$'\e[0m'
BOLD=$'\e[1m'

echo "${BOLD}Checking Funny Gums dependencies...${RESET}"
echo ""

# Define dependencies
# Core - Required for library to function
CORE_DEPS=("bash" "gum" "jq" "awk" "sed" "grep" "date" "tput")

# Development - Required for contributing/testing
DEV_DEPS=("shellcheck" "shfmt")

# Optional - System monitoring modules
EXT_DEPS=("lsblk" "df" "free" "sensors" "lspci" "dmidecode" "inxi" "smartctl" "hdparm" "nmcli")

MISSING_CORE=0
MISSING_DEV=0
MISSING_EXT=0

check_list() {
    local type="$1"
    shift
    local deps=("$@")

    echo "${BOLD}${type} Dependencies:${RESET}"

    for tool in "${deps[@]}"; do
        if command -v "$tool" &>/dev/null; then
            version=""
            # Try to get version cheaply, otherwise skip
            if [[ "$tool" == "bash" ]]; then
                version="($BASH_VERSION)"
            elif [[ "$tool" == "gum" ]]; then
                version="($(gum --version | awk '{print $3}'))"
            elif [[ "$tool" == "shellcheck" ]]; then
                version="($(shellcheck --version | grep '^version:' | awk '{print $2}'))"
            elif [[ "$tool" == "shfmt" ]]; then
                version="($(shfmt --version))"
            fi
            echo "  ${GREEN}✓${RESET} $tool $version"
        else
            echo "  ${RED}✗${RESET} $tool (MISSING)"
            if [[ "$type" == "Core" ]]; then
                ((MISSING_CORE++))
            elif [[ "$type" == "Development" ]]; then
                ((MISSING_DEV++))
            else
                ((MISSING_EXT++))
            fi
        fi
    done
    echo ""
}

check_list "Core" "${CORE_DEPS[@]}"
check_list "Development" "${DEV_DEPS[@]}"
check_list "Optional/System" "${EXT_DEPS[@]}"

echo "----------------------------------------"
if [[ $MISSING_CORE -gt 0 ]]; then
    echo "${RED}FAILURE: Missing $MISSING_CORE core dependencies.${RESET}"
    echo "Please install them to use the library."
    echo ""
    echo "For Ubuntu/Debian, install gum from Charm's official repository:"
    echo "  sudo mkdir -p /etc/apt/keyrings"
    echo "  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
    echo "  echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
    echo "  sudo apt update && sudo apt install gum jq"
    echo ""
    echo "For other systems, see: https://github.com/charmbracelet/gum"
    exit 1
elif [[ $MISSING_DEV -gt 0 ]]; then
    echo "${YELLOW}WARNING: Missing $MISSING_DEV development dependencies.${RESET}"
    echo "These are required for testing and contributing."
    echo "Install with: sudo apt install shellcheck shfmt"
    if [[ $MISSING_EXT -gt 0 ]]; then
        echo ""
        echo "${YELLOW}Also missing $MISSING_EXT system tools.${RESET}"
        echo "Some modules (lib/mod/*) may not function correctly."
    fi
    exit 0
elif [[ $MISSING_EXT -gt 0 ]]; then
    echo "${YELLOW}WARNING: Missing $MISSING_EXT system tools.${RESET}"
    echo "Some modules (lib/mod/*) may not function correctly."
    exit 0
else
    echo "${GREEN}SUCCESS: All dependencies found.${RESET}"
    exit 0
fi
