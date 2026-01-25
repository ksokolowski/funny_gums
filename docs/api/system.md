# System Metrics API

System modules provide hardware monitoring and metrics collection functions.

```bash
source lib/system/system.sh  # All system modules
```

---

## base.sh - Common Utilities

### format_bytes
Format bytes to human-readable string.

```bash
human=$(format_bytes 1234567890)
# Output: "1.2 GiB"
```

### format_kb
Format kilobytes to human-readable string.

```bash
human=$(format_kb 1234567)
# Output: "1.2 GiB"
```

---

## cpu.sh - CPU Metrics

### get_cpu_usage_live
Get CPU usage percentage (requires two samples with 100ms delay).

```bash
cpu_percent=$(get_cpu_usage_live)
# Output: Integer 0-100
```

### get_cpu_temp_live
Get CPU temperature from sensors or sysfs.

```bash
cpu_temp=$(get_cpu_temp_live)
# Output: Integer (Celsius) or empty
```

### get_cpu_freq_live
Get current CPU frequency in MHz.

```bash
freq=$(get_cpu_freq_live)
# Output: Integer (MHz) or empty
```

### get_load_avg_live
Get 1-minute load average.

```bash
load=$(get_load_avg_live)
# Output: Float (e.g., "1.25")
```

---

## memory.sh - Memory Metrics

### get_memory_usage_live
Get memory usage.

```bash
read -r used_kb total_kb percent <<< "$(get_memory_usage_live)"
echo "Using $percent% of memory"
```

**Returns:** `"used_kb total_kb percent"`

### get_swap_usage_live
Get swap usage.

```bash
read -r used_kb total_kb percent <<< "$(get_swap_usage_live)"
echo "Swap: $percent% used"
```

**Returns:** `"used_kb total_kb percent"` (all 0 if no swap)

---

## storage.sh - Disk Metrics

### get_disk_usage_live
Get disk usage for all mounted filesystems.

```bash
get_disk_usage_live
# Output (multiple lines): "mountpoint used_bytes total_bytes percent"
```

### get_root_disk_usage_live
Get root partition usage.

```bash
read -r used_bytes total_bytes percent <<< "$(get_root_disk_usage_live)"
```

### get_physical_drives
Get list of physical drives.

```bash
get_physical_drives
# Output (multiple lines): "device|size_bytes|model|type"
```

**Types:** `ssd`, `hdd`, `nvme`

### get_drive_partitions
Get partitions for a specific drive.

```bash
get_drive_partitions "nvme0n1"
# Output (multiple lines): "partition|size_bytes|fstype|mountpoint|used_bytes"
```

### get_drive_temp
Get drive temperature (via smartctl).

```bash
temp=$(get_drive_temp "sda")
# Output: Temperature in Celsius or empty
```

### get_fstype_color
Get gum color number for filesystem type.

```bash
color=$(get_fstype_color "ext4")
# Output: "2" (green)
```

### get_fstype_color_ansi
Get ANSI color code for filesystem type.

```bash
echo -e "$(get_fstype_color_ansi "ext4")ext4${RESET}"
```

---

## gpu.sh - GPU Metrics

### get_gpu_temp_live
Get GPU temperature (NVIDIA or AMD).

```bash
gpu_temp=$(get_gpu_temp_live)
# Output: Integer (Celsius) or empty
```

Automatically tries:
1. NVIDIA via nvidia-smi
2. AMD via lm-sensors or sysfs

---

## network.sh - Network Metrics

### get_network_interfaces
Get physical network interfaces with status.

```bash
get_network_interfaces
# Output (multiple lines): "interface|type|state|speed|mac|ip|driver|model"
```

**Type:** `ethernet`, `wireless`
**State:** `up`, `down`, `no-driver`

**Example output:**
```
eth0|ethernet|up|1000 Mbps|aa:bb:cc:dd:ee:ff|192.168.1.100|e1000e|Intel I219-V
wlan0|wireless|up|-|ff:ee:dd:cc:bb:aa|192.168.1.101|iwlwifi|Intel Wi-Fi 6
```

### get_wifi_signal
Get wireless signal strength percentage.

```bash
signal=$(get_wifi_signal "wlan0")
# Output: Integer 0-100 or empty
```

---

## inxi.sh - Inxi Integration

Caching wrapper for inxi system information tool.

### inxi_available
Check if inxi is installed.

```bash
if inxi_available; then
    echo "inxi installed"
fi
```

### inxi_raw
Get raw inxi output with caching.

```bash
output=$(inxi_raw "-C" "-c0")
```

### inxi_csv_* functions
Parse inxi output to CSV format for various components:
- `inxi_csv_cpu` - CPU information
- `inxi_csv_memory` - Memory modules
- `inxi_csv_disk` - Disk devices
- `inxi_csv_gpu` - Graphics devices
- `inxi_csv_network` - Network interfaces
- `inxi_csv_audio` - Audio devices
- `inxi_csv_battery` - Battery information

---

## Usage Examples

### System Monitor Script

```bash
#!/usr/bin/env bash
source lib/system/system.sh

# CPU metrics
cpu_usage=$(get_cpu_usage_live)
cpu_temp=$(get_cpu_temp_live)
cpu_freq=$(get_cpu_freq_live)

# Memory metrics
read -r mem_used mem_total mem_pct <<< "$(get_memory_usage_live)"
mem_used_hr=$(format_kb "$mem_used")
mem_total_hr=$(format_kb "$mem_total")

# Display
echo "CPU: ${cpu_usage}% @ ${cpu_freq}MHz (${cpu_temp}°C)"
echo "RAM: ${mem_used_hr} / ${mem_total_hr} (${mem_pct}%)"
```

### Drive Enumeration

```bash
#!/usr/bin/env bash
source lib/system/system.sh

echo "Physical Drives:"
while IFS='|' read -r device size model dtype; do
    size_hr=$(format_bytes "$size")
    echo "  $device: $model ($dtype, $size_hr)"

    # Show partitions
    while IFS='|' read -r part psize fstype mount used; do
        psize_hr=$(format_bytes "$psize")
        echo "    $part: $fstype $psize_hr -> $mount"
    done < <(get_drive_partitions "$device")
done < <(get_physical_drives)
```

### Network Status

```bash
#!/usr/bin/env bash
source lib/system/system.sh
source lib/ui/network.sh

echo "Network Interfaces:"
while IFS='|' read -r iface type state speed mac ip driver model; do
    ui_net_interface_line "$iface" "$type" "$state" "$speed" "$ip" "$model"
done < <(get_network_interfaces)
```
