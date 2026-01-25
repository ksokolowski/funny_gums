# CLI Tool Abstractions API

These modules provide Bash abstractions over common system CLI tools. Each module:
- Checks tool availability before use
- Returns empty strings on failure
- Uses `-` for missing fields in combined outputs
- Requires no dependencies except the underlying CLI tool

---

## sensors.sh - lm-sensors

Abstraction over the `sensors` command from lm-sensors.

```bash
source lib/system/sensors.sh
```

### sensors_available
Check if lm-sensors is installed.

```bash
if sensors_available; then
    temp=$(sensors_get_cpu_temp)
fi
```

### sensors_get_cpu_temp
Get CPU temperature.

```bash
temp=$(sensors_get_cpu_temp)
# Output: Integer (Celsius) or empty
```

### sensors_get_amd_gpu_temp
Get AMD GPU temperature (edge sensor).

```bash
temp=$(sensors_get_amd_gpu_temp)
```

### sensors_get_amd_edge_temp / sensors_get_amd_junction_temp
Get specific AMD GPU temperature sensors.

```bash
edge=$(sensors_get_amd_edge_temp)
junction=$(sensors_get_amd_junction_temp)
```

### sensors_get_all_temps
Get all temperature readings.

```bash
sensors_get_all_temps
# Output (multiple lines): "chip|sensor|temp"
```

### sensors_get_fan_speeds
Get all fan speed readings.

```bash
sensors_get_fan_speeds
# Output (multiple lines): "fan_name|rpm"
```

---

## lspci.sh - PCI Device Queries

Abstraction over the `lspci` command.

```bash
source lib/system/lspci.sh
```

### lspci_available
Check if lspci is installed.

```bash
lspci_available && echo "lspci available"
```

### lspci_get_device_name
Get device name by PCI slot ID.

```bash
name=$(lspci_get_device_name "00:1f.6")
```

### lspci_get_network_devices
Get network devices (Ethernet controllers).

```bash
lspci_get_network_devices
# Output (multiple lines): "pci_id|vendor_device|driver"
```

### lspci_get_gpu_devices
Get GPU devices (VGA and 3D controllers).

```bash
lspci_get_gpu_devices
# Output (multiple lines): "pci_id|vendor_device|driver"
```

### lspci_get_devices
Get all PCI devices with optional filter.

```bash
lspci_get_devices "VGA"
# Output (multiple lines): "pci_id|class|vendor_device"
```

---

## smartctl.sh - Drive Health

Abstraction over `smartctl` (smartmontools) and `nvme-cli`.

```bash
source lib/system/smartctl.sh
```

### smartctl_available / nvme_available
Check if tools are installed.

```bash
smartctl_available && echo "smartctl available"
nvme_available && echo "nvme-cli available"
```

### smartctl_get_temp / nvme_get_temp
Get drive temperature.

```bash
temp=$(smartctl_get_temp "sda")
temp=$(nvme_get_temp "nvme0n1")
```

### smartctl_get_drive_temp
Unified getter (tries SMART then NVMe).

```bash
temp=$(smartctl_get_drive_temp "sda")
```

### smartctl_get_health
Get SMART health status.

```bash
health=$(smartctl_get_health "sda")
# Output: "PASSED" or "FAILED"
```

### nvme_get_health_pct
Get NVMe health percentage remaining.

```bash
pct=$(nvme_get_health_pct "nvme0n1")
# Output: 0-100
```

### smartctl_get_attributes
Get SMART attributes summary.

```bash
smartctl_get_attributes "sda"
# Output (multiple lines): "attribute_name|value|threshold|status"
```

---

## nvidia.sh - NVIDIA GPU

Abstraction over `nvidia-smi`.

```bash
source lib/system/nvidia.sh
```

### nvidia_available
Check if nvidia-smi is installed.

```bash
nvidia_available && echo "nvidia-smi available"
```

### nvidia_get_temp
Get GPU temperature.

```bash
temp=$(nvidia_get_temp)
# Output: Integer (Celsius)
```

### nvidia_get_utilization
Get GPU utilization percentage.

```bash
util=$(nvidia_get_utilization)
# Output: 0-100
```

### nvidia_get_memory_usage
Get GPU memory usage.

```bash
read -r used total <<< "$(nvidia_get_memory_usage)"
# Output: "used_mib total_mib"
```

### nvidia_get_power_draw
Get GPU power draw in watts.

```bash
power=$(nvidia_get_power_draw)
```

### nvidia_get_fan_speed
Get GPU fan speed percentage.

```bash
fan=$(nvidia_get_fan_speed)
```

### nvidia_get_gpu_name
Get GPU model name.

```bash
name=$(nvidia_get_gpu_name)
```

### nvidia_get_clocks
Get GPU clock speeds.

```bash
read -r graphics memory <<< "$(nvidia_get_clocks)"
# Output: "graphics_mhz memory_mhz"
```

### nvidia_get_driver_version
Get driver version.

```bash
version=$(nvidia_get_driver_version)
```

---

## amd.sh - AMD GPU

Abstraction over lm-sensors and sysfs for AMD GPUs.

```bash
source lib/system/amd.sh
```

### amd_gpu_available
Check if AMD GPU is detected.

```bash
amd_gpu_available && echo "AMD GPU detected"
```

### amd_get_temp
Get AMD GPU temperature.

```bash
temp=$(amd_get_temp)
```

### amd_get_edge_temp / amd_get_junction_temp
Get specific temperature sensors.

```bash
edge=$(amd_get_edge_temp)
junction=$(amd_get_junction_temp)
```

### amd_get_fan_speed
Get fan speed in RPM.

```bash
rpm=$(amd_get_fan_speed)
```

### amd_get_power
Get power usage in watts.

```bash
power=$(amd_get_power)
```

### amd_get_vram_usage
Get VRAM usage.

```bash
read -r used total <<< "$(amd_get_vram_usage)"
# Output: "used_bytes total_bytes"
```

---

## hdparm.sh - Disk Parameters

Abstraction over `hdparm` for disk parameter queries.

```bash
source lib/system/hdparm.sh
```

### hdparm_available
Check if hdparm is installed.

```bash
hdparm_available && echo "hdparm available"
```

### hdparm_get_model
Get drive model string.

```bash
model=$(hdparm_get_model "sda")
```

### hdparm_get_serial
Get drive serial number.

```bash
serial=$(hdparm_get_serial "sda")
```

### hdparm_get_firmware
Get firmware version.

```bash
fw=$(hdparm_get_firmware "sda")
```

### hdparm_get_geometry
Get drive geometry.

```bash
geometry=$(hdparm_get_geometry "sda")
# Output: "cylinders heads sectors"
```

### hdparm_get_readonly
Get readonly status.

```bash
ro=$(hdparm_get_readonly "sda")
# Output: "0" (read-write) or "1" (readonly)
```

### hdparm_is_sleeping
Check if drive is in standby/sleep mode.

```bash
if hdparm_is_sleeping "sda"; then
    echo "Drive is sleeping"
fi
```

### hdparm_get_drive_info
Get combined drive info.

```bash
info=$(hdparm_get_drive_info "sda")
# Output: "model|serial|firmware"
```

### hdparm_get_transfer_mode
Get active transfer mode.

```bash
mode=$(hdparm_get_transfer_mode "sda")
# Output: "UDMA/133" or similar
```

---

## dmidecode.sh - BIOS/DMI Info

Abstraction over `dmidecode` for BIOS and motherboard information.

```bash
source lib/system/dmidecode.sh
```

**Note:** Most functions require root/sudo access.

### dmidecode_available
Check if dmidecode is installed.

```bash
dmidecode_available && echo "dmidecode available"
```

### BIOS Information

```bash
vendor=$(dmidecode_get_bios_vendor)
version=$(dmidecode_get_bios_version)
date=$(dmidecode_get_bios_date)

# Combined
info=$(dmidecode_get_bios_info)
# Output: "vendor|version|date"
```

### Motherboard Information

```bash
board_name=$(dmidecode_get_board_name)
board_vendor=$(dmidecode_get_board_vendor)

# Combined
info=$(dmidecode_get_board_info)
# Output: "vendor|name"
```

### System Information

```bash
system_name=$(dmidecode_get_system_name)
system_vendor=$(dmidecode_get_system_vendor)
system_serial=$(dmidecode_get_system_serial)
chassis=$(dmidecode_get_chassis_type)
# Output: "Desktop", "Laptop", "Server", etc.
```

### Memory Information

```bash
slots=$(dmidecode_get_memory_slots)
# Output: Number of memory slots

dmidecode_get_memory_info
# Output (multiple lines): "slot|size|type|speed|manufacturer"
```

### Processor Information

```bash
dmidecode_get_processor_info
# Output (multiple lines): "socket|name|cores|threads|speed"
```

---

## power.sh - Battery/AC Power

Abstraction over `acpi` and `upower` for power management.

```bash
source lib/system/power.sh
```

### power_available
Check if acpi or upower is installed.

```bash
power_available && echo "Power tools available"
```

### power_on_ac
Check if on AC power.

```bash
if power_on_ac; then
    echo "On AC power"
else
    echo "On battery"
fi
```

### power_has_battery
Check if battery is present.

```bash
if power_has_battery; then
    echo "Battery present"
fi
```

### power_get_battery_percent
Get battery charge percentage.

```bash
pct=$(power_get_battery_percent)
# Output: 0-100
```

### power_get_battery_status
Get battery status.

```bash
status=$(power_get_battery_status)
# Output: "Charging", "Discharging", "Full", "Not charging", "Unknown"
```

### power_get_battery_time
Get time remaining (charging or discharging).

```bash
time=$(power_get_battery_time)
# Output: "HH:MM" or empty
```

### power_get_battery_health
Get battery health percentage.

```bash
health=$(power_get_battery_health)
# Output: Percentage of design capacity
```

### power_get_thermal_zones
Get thermal zone information.

```bash
power_get_thermal_zones
# Output (multiple lines): "zone|temp|type"
```

### power_get_battery_info
Get combined battery info.

```bash
info=$(power_get_battery_info)
# Output: "percent|status|time|health"
```

---

## Usage Example

```bash
#!/usr/bin/env bash
source lib/system/system.sh

echo "System Information"
echo "=================="

# BIOS/Board info (requires sudo)
if dmidecode_available; then
    IFS='|' read -r vendor name <<< "$(dmidecode_get_board_info)"
    echo "Motherboard: $vendor $name"
fi

# GPU info
if nvidia_available; then
    name=$(nvidia_get_gpu_name)
    temp=$(nvidia_get_temp)
    echo "GPU: $name @ ${temp}°C"
elif amd_gpu_available; then
    temp=$(amd_get_temp)
    echo "AMD GPU @ ${temp}°C"
fi

# Power info
if power_available; then
    if power_has_battery; then
        pct=$(power_get_battery_percent)
        status=$(power_get_battery_status)
        echo "Battery: ${pct}% ($status)"
    fi
fi
```
