#!/usr/bin/env bash
# test_inxi_helper.sh - Test suite for inxi_helper.sh
# shellcheck disable=SC1091

# Source test framework
source "$(dirname "$0")/framework.sh"

# Source library
source "$(dirname "$0")/../lib/mod/os/inxi.sh"

test_file_start "inxi.sh"

# Mock inxi output
MOCK_INXI_OUTPUT=$(
    cat <<'EOF'
System:
  Kernel: 6.14.0-37-generic arch: x86_64 bits: 64 compiler: gcc v: 14.2.0
  Desktop: GNOME v: 48.0 Distro: Ubuntu 25.04 (Plucky Puffin)

Machine:
  Type: Desktop System: ASUS product: N/A v: N/A serial: <superuser required>

CPU:
  Info: 16-core model: AMD Ryzen 9 9950X3D bits: 64 type: MT MCP arch: N/A

Graphics:
  Device-1: NVIDIA GB202 [GeForce RTX 5090] vendor: ASUSTeK driver: nvidia

Audio:
  Device-1: NVIDIA driver: snd_hda_intel v: kernel

Network:
  Device-1: Intel Ethernet I226-V vendor: ASUSTeK driver: igc

Drives:
  Local Storage: total: 16.42 TiB used: 1.21 TiB (7.4%)
  ID-1: /dev/nvme0n1 vendor: Samsung model: SSD 990 PRO 2TB size: 1.82 TiB

Partition:
  ID-1: / size: 1.83 TiB used: 384.46 GiB (20.5%) fs: ext4 dev: /dev/nvme1n1p2

Sensors:
  System Temperatures: cpu: 49.8 C mobo: N/A

Info:
  Memory: total: 96 GiB available: 91.68 GiB used: 10.44 GiB (11.4%)
EOF
)

# Override inxi_cache_data to use mock
inxi_cache_data() {
    INXI_CACHE="$MOCK_INXI_OUTPUT"
}

it_parses_system_section() {
    inxi_cache_data
    local output=$(inxi_parse_system_csv)
    assert_contains "Kernel,6.14.0-37-generic arch: x86_64 bits: 64 compiler: gcc v: 14.2.0" "$output"
    assert_contains "Desktop,GNOME v: 48.0 Distro: Ubuntu 25.04 (Plucky Puffin)" "$output"
}

it_parses_cpu_section() {
    inxi_cache_data
    local output=$(inxi_parse_cpu_csv)
    assert_contains "Info,16-core model: AMD Ryzen 9 9950X3D bits: 64 type: MT MCP arch: N/A" "$output"
}

it_parses_partition_section() {
    inxi_cache_data
    local output=$(inxi_parse_partition_csv)
    # / (1),1.83 TiB,384.46 GiB (20.5%),ext4,/dev/nvme1n1p2
    assert_contains "/ (1),1.83 TiB,384.46 GiB (20.5%),ext4,/dev/nvme1n1p2" "$output"
}

it_parses_memory_info() {
    inxi_cache_data
    local output=$(inxi_parse_memory_csv)
    assert_contains "Total,96 GiB" "$output"
    assert_contains "Used,10.44 GiB (11.4%)" "$output"
}

it_parses_system_section
it_parses_cpu_section
it_parses_partition_section
it_parses_memory_info

print_summary
