#!/usr/bin/env bash
# inxi.sh - Inxi caching and parsing functions
# shellcheck disable=SC2034,SC2155

[[ -n "${_SYSTEM_INXI_LOADED:-}" ]] && return 0
_SYSTEM_INXI_LOADED=1

# Cached inxi output
INXI_CACHE=""

# Run inxi and cache output
# Usage: inxi_cache_data
inxi_cache_data() {
    INXI_CACHE=$(inxi -Fxz -c0)
}

# Get a section from cached inxi output
# Usage: inxi_get_section "CPU"
inxi_get_section() {
    local section="$1"
    # Matches lines starting with the section name until the next line starting with a capital letter followed by a colon
    echo "$INXI_CACHE" | awk "/^$section:/{flag=1; print \$0; next} /^[A-Z][a-zA-Z]*:/{flag=0} flag"
}

# Parse a section and return key-value pairs in CSV format
# Usage: inxi_parse_generic "CPU"
inxi_parse_generic() {
    local section_name="$1"
    local section_data=$(inxi_get_section "$section_name")

    if [[ -z "$section_data" ]]; then
        return 1
    fi

    # Efficient parsing with AWK (replaces loop+regex)
    # 1. Skip first line (header)
    # 2. Match pattern "Label: Value"
    # 3. Print as "Label,Value"
    echo "$section_data" | awk '
        NR > 1 {
            # Use split to separate Label: Value chunks if multiple per line
            # This handles input like "Label1: Value1 Label2: Value2" somewhat, 
            # though inxi -c0 usually puts them on separate lines or formats them predictably.
            
            # Simple approach: find the first colon, everything before is label, after is value
            $0 = substr($0, match($0, /[a-zA-Z0-9]/)) # Trim leading whitespace
            n = index($0, ":")
            if (n > 0) {
                label = substr($0, 1, n-1)
                value = substr($0, n+2) # Skip ": "
                print label "," value
            }
        }
    '
}

# Specialized parsers

inxi_parse_system_csv() {
    echo "Item,Value"
    inxi_parse_generic "System"
}

inxi_parse_machine_csv() {
    echo "Item,Value"
    inxi_parse_generic "Machine"
}

inxi_parse_cpu_csv() {
    echo "Item,Value"
    inxi_parse_generic "CPU"
}

inxi_parse_graphics_csv() {
    echo "Item,Value"
    inxi_parse_generic "Graphics"
}

inxi_parse_audio_csv() {
    echo "Item,Value"
    inxi_parse_generic "Audio"
}

inxi_parse_network_csv() {
    echo "Item,Value"
    inxi_parse_generic "Network"
}

inxi_parse_storage_csv() {
    echo "Item,Value"
    # Storage uses 'ID-1:', 'ID-2:' etc.
    inxi_parse_generic "Drives"
}

inxi_parse_partition_csv() {
    echo "ID,Size,Used,FS,Device"
    inxi_get_section "Partition" | sed '1d' | sed 's/^[[:space:]]*//' | while read -r line; do
        if [[ $line =~ ^ID-([0-9]+):[[:space:]](.*)$ ]]; then
            # ID-1: / size: 1.83 TiB used: 384.46 GiB (20.5%) fs: ext4 dev: /dev/nvme1n1p2
            id="${BASH_REMATCH[1]}"
            rest="${BASH_REMATCH[2]}"

            size=$(echo "$rest" | grep -oP "size: \K[^ ]+ [^ ]+")
            used=$(echo "$rest" | grep -oP "used: \K[^ ]+ [^ ]+ \([^)]+\)")
            fs=$(echo "$rest" | grep -oP "fs: \K[^ ]+")
            dev=$(echo "$rest" | grep -oP "dev: \K[^ ]+")
            mnt=$(echo "$rest" | awk '{print $1}')

            echo "$mnt ($id),$size,$used,$fs,$dev"
        fi
    done
}

inxi_parse_sensors_csv() {
    echo "Item,Value"
    inxi_parse_generic "Sensors"
}

inxi_parse_memory_csv() {
    echo "Item,Value"
    local mem_line=$(inxi_get_section "Info" | grep "Memory:")
    if [[ $mem_line =~ Memory:[[:space:]](.*) ]]; then
        local rest="${BASH_REMATCH[1]}"

        local total=$(echo "$rest" | sed -n 's/.*total: \([^ ]* [^ ]*\).*/\1/p')
        local available=$(echo "$rest" | sed -n 's/.*available: \([^ ]* [^ ]*\).*/\1/p')
        local used=$(echo "$rest" | sed -n 's/.*used: \([^ ]* [^ ]* ([^)]*)\).*/\1/p')

        [[ -n "$total" ]] && echo "Total,$total"
        [[ -n "$available" ]] && echo "Available,$available"
        [[ -n "$used" ]] && echo "Used,$used"
    fi
}
