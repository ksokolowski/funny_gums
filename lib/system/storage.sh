#!/usr/bin/env bash
# storage.sh - Storage and disk monitoring functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_STORAGE_LOADED:-}" ]] && return 0
_SYSTEM_STORAGE_LOADED=1

# Source dependencies
_SYSTEM_STORAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SYSTEM_STORAGE_DIR/../core/colors.sh"
source "$_SYSTEM_STORAGE_DIR/smartctl.sh"

# Get disk usage for all mounted filesystems
# Usage: get_disk_usage_live
# Returns: Multiple lines of "mountpoint used_bytes total_bytes percent"
get_disk_usage_live() {
    df -B1 --output=target,used,size,pcent 2>/dev/null | tail -n +2 | \
        grep -E "^/" | while read -r mount used total percent; do
        # Remove % sign from percent
        percent="${percent%\%}"
        echo "$mount $used $total $percent"
    done
}

# Get root partition usage specifically
# Usage: read -r used_bytes total_bytes percent <<< "$(get_root_disk_usage_live)"
get_root_disk_usage_live() {
    df -B1 --output=used,size,pcent / 2>/dev/null | tail -1 | \
        awk '{gsub(/%/,"",$3); print $1, $2, $3}'
}

# Get list of physical drives (excludes loop, zram, etc.)
# Usage: get_physical_drives
# Returns: Lines of "device|size_bytes|model|type" (type: ssd/hdd/nvme)
get_physical_drives() {
    # Use separate lsblk calls to avoid column parsing issues with spaces in model names
    lsblk -d -o NAME -n 2>/dev/null | grep -vE "^(loop|zram|sr)" | while read -r name; do
        [[ -z "$name" ]] && continue

        # Get individual attributes
        local size model rota tran
        size=$(lsblk -b -d -o SIZE -n "/dev/$name" 2>/dev/null)
        model=$(lsblk -d -o MODEL -n "/dev/$name" 2>/dev/null | sed 's/^ *//;s/ *$//')
        rota=$(lsblk -d -o ROTA -n "/dev/$name" 2>/dev/null)
        tran=$(lsblk -d -o TRAN -n "/dev/$name" 2>/dev/null)

        [[ -z "$size" ]] && continue
        [[ -z "$model" ]] && model="Unknown"

        # Determine drive type
        local dtype="hdd"
        if [[ "$tran" == "nvme" ]]; then
            dtype="nvme"
        elif [[ "$rota" == "0" ]]; then
            dtype="ssd"
        fi

        echo "$name|$size|$model|$dtype"
    done
}

# Get partitions for a specific drive
# Usage: get_drive_partitions "nvme0n1"
# Returns: Lines of "partition|size_bytes|fstype|mountpoint|used_bytes"
get_drive_partitions() {
    local drive="$1"

    lsblk -b -o NAME,SIZE,FSTYPE,MOUNTPOINT -n "/dev/$drive" 2>/dev/null | \
        tail -n +2 | while read -r name size fstype mountpoint; do
        [[ -z "$name" ]] && continue

        # Clean partition name (remove tree characters)
        name=$(echo "$name" | sed 's/[├└─│ ]//g')

        # Get used space if mounted
        local used=0
        if [[ -n "$mountpoint" ]] && [[ "$mountpoint" != "[SWAP]" ]]; then
            used=$(df -B1 "$mountpoint" 2>/dev/null | tail -1 | awk '{print $3}')
        fi
        [[ -z "$used" ]] && used=0

        # Handle empty fstype
        [[ -z "$fstype" ]] && fstype="unknown"
        [[ -z "$mountpoint" ]] && mountpoint="-"

        echo "$name|$size|$fstype|$mountpoint|$used"
    done
}

# Get drive health/temperature if available (via smartctl module)
# Usage: get_drive_temp "sda"
# Returns: Temperature in Celsius or empty
get_drive_temp() {
    local drive="$1"
    smartctl_get_drive_temp "$drive"
}

# Filesystem type to color mapping (gum color number)
# Usage: color=$(get_fstype_color "ext4")
get_fstype_color() {
    local fstype="$1"
    case "$fstype" in
        ext4|ext3|ext2)   echo "2"   ;;  # Green
        ntfs)             echo "4"   ;;  # Blue
        vfat|fat32|exfat) echo "3"   ;;  # Yellow
        btrfs)            echo "6"   ;;  # Cyan
        xfs)              echo "5"   ;;  # Magenta
        swap)             echo "1"   ;;  # Red
        *)                echo "8"   ;;  # Gray
    esac
}

# Get filesystem type display color (ANSI)
# Usage: echo -e "$(get_fstype_color_ansi "ext4")ext4${RESET}"
get_fstype_color_ansi() {
    local fstype="$1"
    case "$fstype" in
        ext4|ext3|ext2)   echo "$NEON_GREEN"   ;;
        ntfs)             echo "$NEON_BLUE"    ;;
        vfat|fat32|exfat) echo "$NEON_YELLOW"  ;;
        btrfs)            echo "$NEON_CYAN"    ;;
        xfs)              echo "$NEON_PURPLE"  ;;
        swap)             echo "$NEON_RED"     ;;
        *)                echo "$BRIGHT_BLACK" ;;
    esac
}
