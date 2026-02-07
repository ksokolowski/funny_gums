#!/usr/bin/env bash
# storage.sh - Storage and partition visualization functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_UI_STORAGE_LOADED:-}" ]] && return 0
_UI_STORAGE_LOADED=1

# Source dependencies
_UI_STORAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_UI_STORAGE_DIR/../../core/term/colors.sh"
source "$_UI_STORAGE_DIR/../../ui/widgets/gauge.sh"

#---------------------------------------
# Partition layout visualization
#---------------------------------------

# Partition layout colors by filesystem type
declare -A _UI_FSTYPE_COLORS=(
    ["ext4"]="$NEON_GREEN"
    ["ext3"]="$NEON_GREEN"
    ["ext2"]="$NEON_GREEN"
    ["ntfs"]="$NEON_BLUE"
    ["vfat"]="$NEON_YELLOW"
    ["fat32"]="$NEON_YELLOW"
    ["exfat"]="$NEON_YELLOW"
    ["btrfs"]="$NEON_CYAN"
    ["xfs"]="$NEON_PURPLE"
    ["swap"]="$NEON_RED"
    ["unknown"]="$BRIGHT_BLACK"
)

# Get color for a filesystem type
# Usage: color=$(_ui_fstype_color "ext4")
_ui_fstype_color() {
    local fstype="${1:-unknown}"
    echo "${_UI_FSTYPE_COLORS[$fstype]:-$BRIGHT_BLACK}"
}

# Build a partition layout bar showing multiple partitions proportionally
# Usage: ui_partition_bar <total_size> <width> "size1|color1" "size2|color2" ...
# Each segment is: "size_bytes|ansi_color"
# Example: ui_partition_bar 1000000000 40 "500000000|$NEON_GREEN" "500000000|$NEON_BLUE"
ui_partition_bar() {
    local total_size=$1
    local width=$2
    shift 2

    local bar=""
    local used_width=0

    # Build segments proportionally
    for segment in "$@"; do
        local seg_size="${segment%%|*}"
        local seg_color="${segment#*|}"

        # Calculate width for this segment
        local seg_width=0
        if [[ $total_size -gt 0 ]]; then
            seg_width=$((seg_size * width / total_size))
        fi

        # Ensure at least 1 char for non-empty partitions
        [[ $seg_size -gt 0 ]] && [[ $seg_width -eq 0 ]] && seg_width=1

        # Don't exceed total width
        if ((used_width + seg_width > width)); then
            seg_width=$((width - used_width))
        fi

        # Build this segment
        if [[ $seg_width -gt 0 ]]; then
            local i
            for ((i = 0; i < seg_width; i++)); do
                bar+="${seg_color}█${RESET}"
            done
            used_width=$((used_width + seg_width))
        fi
    done

    # Fill remaining space with empty blocks (unallocated)
    local remaining=$((width - used_width))
    if [[ $remaining -gt 0 ]]; then
        local i
        for ((i = 0; i < remaining; i++)); do
            bar+="${DIM}░${RESET}"
        done
    fi

    echo -e "$bar"
}

# Build a drive visualization with partition layout
# Usage: ui_drive_layout "model" "size_hr" "type" <total_bytes> <bar_width> "partitions..."
# Where partitions are: "name|size_bytes|fstype|mountpoint|used_bytes"
ui_drive_layout() {
    local model="$1"
    local size_hr="$2"
    local drive_type="$3"
    local total_bytes=$4
    local bar_width=$5
    shift 5

    local icon
    case "$drive_type" in
    nvme) icon="⚡" ;;
    ssd) icon="💾" ;;
    hdd) icon="💿" ;;
    *) icon="📀" ;;
    esac

    local output=""
    output+="${BOLD}$icon $model${RESET} ${DIM}($size_hr)${RESET}\n"

    # Build partition bar segments
    local segments=()
    local partition_lines=""

    for part_data in "$@"; do
        IFS='|' read -r name size fstype mountpoint used <<<"$part_data"

        local color
        color=$(_ui_fstype_color "$fstype")
        segments+=("$size|$color")

        # Format partition info line
        local size_hr_part
        size_hr_part=$(format_bytes "$size" 2>/dev/null || echo "${size}B")

        local mount_str=""
        [[ "$mountpoint" != "-" ]] && mount_str=" → $mountpoint"

        local used_str=""
        if [[ "$used" -gt 0 ]] && [[ "$size" -gt 0 ]]; then
            local used_pct=$((used * 100 / size))
            local used_hr
            used_hr=$(format_bytes "$used" 2>/dev/null || echo "${used}B")
            used_str=" [${used_hr} used, ${used_pct}%]"
        fi

        partition_lines+="   ${color}█${RESET} $name: $fstype $size_hr_part$mount_str$used_str\n"
    done

    # Build the bar
    output+="   ["
    output+=$(ui_partition_bar "$total_bytes" "$bar_width" "${segments[@]}")
    output+="]\n"

    # Add partition details
    output+="$partition_lines"

    echo -e "$output"
}

# Generate filesystem legend
# Usage: ui_fs_legend
ui_fs_legend() {
    local legend=""
    legend+="${NEON_GREEN}█${RESET}ext4 "
    legend+="${NEON_BLUE}█${RESET}ntfs "
    legend+="${NEON_YELLOW}█${RESET}fat "
    legend+="${NEON_CYAN}█${RESET}btrfs "
    legend+="${NEON_PURPLE}█${RESET}xfs "
    legend+="${NEON_RED}█${RESET}swap "
    legend+="${DIM}░${RESET}free"
    echo -e "$legend"
}
