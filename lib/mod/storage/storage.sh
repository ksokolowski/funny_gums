#!/usr/bin/env bash
# storage.sh - Storage and disk monitoring functions
# shellcheck disable=SC2034,SC1091

[[ -n "${_SYSTEM_STORAGE_LOADED:-}" ]] && return 0
_SYSTEM_STORAGE_LOADED=1

# Source dependencies
_SYSTEM_STORAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SYSTEM_STORAGE_DIR/../../core/term/colors.sh"
source "$_SYSTEM_STORAGE_DIR/smartctl.sh"
source "$_SYSTEM_STORAGE_DIR/../hw/sensors.sh"

# Get disk usage for all mounted filesystems
# Usage: get_disk_usage_live
# Returns: Multiple lines of "mountpoint used_bytes total_bytes percent"
get_disk_usage_live() {
    df -B1 --output=target,used,size,pcent 2>/dev/null | tail -n +2 |
        grep -E "^/" | while read -r mount used total percent; do
        # Remove % sign from percent
        percent="${percent%\%}"
        echo "$mount $used $total $percent"
    done
}

# Get root partition usage specifically
# Usage: read -r used_bytes total_bytes percent <<< "$(get_root_disk_usage_live)"
get_root_disk_usage_live() {
    df -B1 --output=used,size,pcent / 2>/dev/null | tail -1 |
        awk '{gsub(/%/,"",$3); print $1, $2, $3}'
}

# Get list of physical drives (excludes loop, zram, etc.)
# Usage: get_physical_drives
# Returns: Lines of "device|size_bytes|model|type" (type: ssd/hdd/nvme)
get_physical_drives() {
    # Requires jq for JSON parsing
    command -v jq &>/dev/null || return 1

    # One-pass JSON parsing with jq for efficiency
    # Ignores types: loop, zram, rom (sr*)
    lsblk -J -b -d -o NAME,SIZE,MODEL,ROTA,TRAN,TYPE 2>/dev/null | jq -r '
        .blockdevices[] | 
        select(.type != "loop" and .type != "rom" and (.name | test("^zram") | not)) |
        [
            .name,
            .size,
            (.model? // "Unknown" | sub("^\\s+"; "") | sub("\\s+$"; "")),
            (if .tran == "nvme" then "nvme" 
             elif .rota == false or .rota == "0" then "ssd" 
             else "hdd" end)
        ] | join("|")
    '
}

# Get partitions for a specific drive
# Usage: get_drive_partitions "nvme0n1"
# Returns: Lines of "partition|size_bytes|fstype|mountpoint|used_bytes"
get_drive_partitions() {
    local drive="$1"

    lsblk -r -b -o NAME,SIZE,FSTYPE,MOUNTPOINT -n "/dev/$drive" 2>/dev/null |
        tail -n +2 | while read -r name size fstype mountpoint; do
        [[ -z "$name" ]] && continue

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

# Resolve drive to PCI ID if possible
get_drive_pci_id() {
    local drive="$1"
    # Try sysfs
    local sys_path="/sys/block/$drive/device"
    if [[ -L "$sys_path" ]]; then
        local full_path
        full_path=$(readlink -f "$sys_path")
        # Extract PCI ID (0000:00:00.0) from path
        # Grep matching valid PCI addresses, take the last one likely effectively the device
        if [[ "$full_path" =~ ([0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]) ]]; then
            echo "${BASH_REMATCH[1]}"
            return
        fi
    fi
}

# Get drive health/temperature if available (via sensors or smartctl)
# Usage: get_drive_temp "sda"
# Returns: Temperature in Celsius or empty
get_drive_temp() {
    local drive="$1"

    # Try via mapped sensors first (faster, no wakeup)
    local pci_id
    pci_id=$(get_drive_pci_id "$drive")
    if [[ -n "$pci_id" ]]; then
        local sens_temp
        sens_temp=$(sensors_get_temp_by_pci_id "$pci_id")
        if [[ -n "$sens_temp" ]]; then
            echo "$sens_temp"
            return
        fi
    fi

    # Fallback to smartctl
    smartctl_get_drive_temp "$drive"
}

# Filesystem type to color mapping (gum color number)
# Usage: color=$(get_fstype_color "ext4")
get_fstype_color() {
    local fstype="$1"
    case "$fstype" in
    ext4 | ext3 | ext2) echo "2" ;;   # Green
    ntfs) echo "4" ;;                 # Blue
    vfat | fat32 | exfat) echo "3" ;; # Yellow
    btrfs) echo "6" ;;                # Cyan
    xfs) echo "5" ;;                  # Magenta
    swap) echo "1" ;;                 # Red
    *) echo "8" ;;                    # Gray
    esac
}

# Get filesystem type display color (ANSI)
# Usage: echo -e "$(get_fstype_color_ansi "ext4")ext4${RESET}"
get_fstype_color_ansi() {
    local fstype="$1"
    case "$fstype" in
    ext4 | ext3 | ext2) echo "$NEON_GREEN" ;;
    ntfs) echo "$NEON_BLUE" ;;
    vfat | fat32 | exfat) echo "$NEON_YELLOW" ;;
    btrfs) echo "$NEON_CYAN" ;;
    xfs) echo "$NEON_PURPLE" ;;
    swap) echo "$NEON_RED" ;;
    *) echo "$BRIGHT_BLACK" ;;
    esac
}
