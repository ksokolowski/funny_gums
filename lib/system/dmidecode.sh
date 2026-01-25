#!/usr/bin/env bash
# dmidecode.sh - BIOS/DMI information abstraction module
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_DMIDECODE_LOADED:-}" ]] && return 0
_SYSTEM_DMIDECODE_LOADED=1

# Check if dmidecode is installed
# Usage: dmidecode_available && echo "dmidecode installed"
dmidecode_available() {
    command -v dmidecode &>/dev/null
}

# Get BIOS vendor
# Usage: vendor=$(dmidecode_get_bios_vendor)
# Returns: BIOS vendor string or empty
dmidecode_get_bios_vendor() {
    dmidecode_available || return 1
    sudo dmidecode -s bios-vendor 2>/dev/null | head -1
}

# Get BIOS version
# Usage: version=$(dmidecode_get_bios_version)
# Returns: BIOS version string or empty
dmidecode_get_bios_version() {
    dmidecode_available || return 1
    sudo dmidecode -s bios-version 2>/dev/null | head -1
}

# Get BIOS release date
# Usage: date=$(dmidecode_get_bios_date)
# Returns: BIOS release date string or empty
dmidecode_get_bios_date() {
    dmidecode_available || return 1
    sudo dmidecode -s bios-release-date 2>/dev/null | head -1
}

# Get motherboard/baseboard name/model
# Usage: board=$(dmidecode_get_board_name)
# Returns: Board product name or empty
dmidecode_get_board_name() {
    dmidecode_available || return 1
    sudo dmidecode -s baseboard-product-name 2>/dev/null | head -1
}

# Get motherboard/baseboard vendor/manufacturer
# Usage: vendor=$(dmidecode_get_board_vendor)
# Returns: Board manufacturer or empty
dmidecode_get_board_vendor() {
    dmidecode_available || return 1
    sudo dmidecode -s baseboard-manufacturer 2>/dev/null | head -1
}

# Get system product name
# Usage: name=$(dmidecode_get_system_name)
# Returns: System product name or empty
dmidecode_get_system_name() {
    dmidecode_available || return 1
    sudo dmidecode -s system-product-name 2>/dev/null | head -1
}

# Get system vendor/manufacturer
# Usage: vendor=$(dmidecode_get_system_vendor)
# Returns: System manufacturer or empty
dmidecode_get_system_vendor() {
    dmidecode_available || return 1
    sudo dmidecode -s system-manufacturer 2>/dev/null | head -1
}

# Get system serial number
# Usage: serial=$(dmidecode_get_system_serial)
# Returns: System serial number or empty
dmidecode_get_system_serial() {
    dmidecode_available || return 1
    sudo dmidecode -s system-serial-number 2>/dev/null | head -1
}

# Get total memory slot count
# Usage: slots=$(dmidecode_get_memory_slots)
# Returns: Number of memory slots or empty
dmidecode_get_memory_slots() {
    dmidecode_available || return 1
    sudo dmidecode -t memory 2>/dev/null | grep -c "Memory Device$" || echo "0"
}

# Get memory information for each slot
# Usage: dmidecode_get_memory_info
# Returns: Lines of "slot|size|type|speed|manufacturer|configured_speed"
dmidecode_get_memory_info() {
    dmidecode_available || return 1

    local in_device=0
    local slot="" size="" type="" speed="" mfr="" conf_speed=""
    local slot_num=0

    sudo dmidecode -t memory 2>/dev/null | while IFS= read -r line; do
        # Detect start of Memory Device section
        if [[ "$line" == "Memory Device" ]]; then
            # Output previous device if we had one with size
            if [[ $in_device -eq 1 && -n "$size" && "$size" != "No Module Installed" ]]; then
                [[ -z "$slot" ]] && slot="Slot $slot_num"
                [[ -z "$type" ]] && type="-"
                [[ -z "$speed" ]] && speed="-"
                [[ -z "$mfr" ]] && mfr="-"
                [[ -z "$conf_speed" ]] && conf_speed="-"
                echo "${slot}|${size}|${type}|${speed}|${mfr}|${conf_speed}"
            fi
            in_device=1
            slot=""
            size=""
            type=""
            speed=""
            mfr=""
            conf_speed=""
            slot_num=$((slot_num + 1))
            continue
        fi

        if [[ $in_device -eq 1 ]]; then
            case "$line" in
                *"Locator:"*)
                    if [[ "$line" != *"Bank Locator:"* ]]; then
                        slot=$(echo "$line" | sed 's/.*Locator: *//')
                    fi
                    ;;
                *"Size:"*)
                    size=$(echo "$line" | sed 's/.*Size: *//')
                    ;;
                *"Type:"*)
                    if [[ "$line" != *"Type Detail:"* && "$line" != *"Error Correction Type:"* ]]; then
                        type=$(echo "$line" | sed 's/.*Type: *//')
                    fi
                    ;;
                *"Speed:"*)
                    if [[ "$line" != *"Configured"* ]]; then
                        speed=$(echo "$line" | sed 's/.*Speed: *//')
                    fi
                    ;;
                *"Configured Memory Speed:"*)
                    conf_speed=$(echo "$line" | sed 's/.*Configured Memory Speed: *//')
                    ;;
                *"Manufacturer:"*)
                    mfr=$(echo "$line" | sed 's/.*Manufacturer: *//')
                    ;;
            esac
        fi
    done

    # Handle last device (the while loop is in a subshell, so this won't capture it)
    # Re-run to capture last entry
    sudo dmidecode -t memory 2>/dev/null | awk '
        /^Memory Device$/ {
            if (size != "" && size != "No Module Installed") {
                if (slot == "") slot = "Slot " slot_num
                if (type == "") type = "-"
                if (speed == "") speed = "-"
                if (mfr == "") mfr = "-"
                if (conf_speed == "") conf_speed = "-"
                print slot "|" size "|" type "|" speed "|" mfr "|" conf_speed
            }
            slot = ""
            size = ""
            type = ""
            speed = ""
            mfr = ""
            conf_speed = ""
            slot_num++
            in_device = 1
            next
        }
        in_device == 1 {
            if ($0 ~ /Locator:/ && $0 !~ /Bank Locator:/) {
                gsub(/.*Locator: */, "")
                slot = $0
            }
            if ($0 ~ /Size:/) {
                gsub(/.*Size: */, "")
                size = $0
            }
            if ($0 ~ /Type:/ && $0 !~ /Type Detail:/ && $0 !~ /Error Correction Type:/) {
                gsub(/.*Type: */, "")
                type = $0
            }
            if ($0 ~ /Speed:/ && $0 !~ /Configured/) {
                gsub(/.*Speed: */, "")
                speed = $0
            }
            if ($0 ~ /Configured Memory Speed:/) {
                gsub(/.*Configured Memory Speed: */, "")
                conf_speed = $0
            }
            if ($0 ~ /Manufacturer:/) {
                gsub(/.*Manufacturer: */, "")
                mfr = $0
            }
        }
        END {
            if (size != "" && size != "No Module Installed") {
                if (slot == "") slot = "Slot " slot_num
                if (type == "") type = "-"
                if (speed == "") speed = "-"
                if (mfr == "") mfr = "-"
                if (conf_speed == "") conf_speed = "-"
                print slot "|" size "|" type "|" speed "|" mfr "|" conf_speed
            }
        }
    '
}

# Get chassis type
# Usage: chassis=$(dmidecode_get_chassis_type)
# Returns: Chassis type (Desktop, Laptop, Server, etc.) or empty
dmidecode_get_chassis_type() {
    dmidecode_available || return 1
    sudo dmidecode -s chassis-type 2>/dev/null | head -1
}

# Get processor information
# Usage: dmidecode_get_processor_info
# Returns: Lines of "socket|name|cores|threads|speed"
dmidecode_get_processor_info() {
    dmidecode_available || return 1

    sudo dmidecode -t processor 2>/dev/null | awk '
        /^Processor Information$/ {
            if (socket != "" && name != "") {
                if (cores == "") cores = "-"
                if (threads == "") threads = "-"
                if (speed == "") speed = "-"
                print socket "|" name "|" cores "|" threads "|" speed
            }
            socket = ""
            name = ""
            cores = ""
            threads = ""
            speed = ""
            in_proc = 1
            next
        }
        in_proc == 1 {
            if ($0 ~ /Socket Designation:/) {
                gsub(/.*Socket Designation: */, "")
                socket = $0
            }
            if ($0 ~ /Version:/) {
                gsub(/.*Version: */, "")
                name = $0
            }
            if ($0 ~ /Core Count:/) {
                gsub(/.*Core Count: */, "")
                cores = $0
            }
            if ($0 ~ /Thread Count:/) {
                gsub(/.*Thread Count: */, "")
                threads = $0
            }
            if ($0 ~ /Current Speed:/) {
                gsub(/.*Current Speed: */, "")
                speed = $0
            }
        }
        END {
            if (socket != "" && name != "") {
                if (cores == "") cores = "-"
                if (threads == "") threads = "-"
                if (speed == "") speed = "-"
                print socket "|" name "|" cores "|" threads "|" speed
            }
        }
    '
}

# Get combined BIOS info
# Usage: info=$(dmidecode_get_bios_info)
# Returns: "vendor|version|date" or empty
dmidecode_get_bios_info() {
    dmidecode_available || return 1

    local vendor version date
    vendor=$(dmidecode_get_bios_vendor)
    version=$(dmidecode_get_bios_version)
    date=$(dmidecode_get_bios_date)

    [[ -z "$vendor" ]] && vendor="-"
    [[ -z "$version" ]] && version="-"
    [[ -z "$date" ]] && date="-"

    echo "${vendor}|${version}|${date}"
}

# Get combined board info
# Usage: info=$(dmidecode_get_board_info)
# Returns: "vendor|name" or empty
dmidecode_get_board_info() {
    dmidecode_available || return 1

    local vendor name
    vendor=$(dmidecode_get_board_vendor)
    name=$(dmidecode_get_board_name)

    [[ -z "$vendor" ]] && vendor="-"
    [[ -z "$name" ]] && name="-"

    echo "${vendor}|${name}"
}
