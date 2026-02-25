# Roadmap 🗺️

This document outlines the implemented CLI tool abstractions and planned future integrations for Funny Gums.

---

These modules are complete with availability checks, error handling, and test coverage.

### Core System Tools

| Module | Tool | Purpose | Status |
|--------|------|---------|--------|
| `sensors.sh` | lm-sensors | CPU/GPU temperatures, fan speeds | ✅ Implemented |
| `lspci.sh` | pciutils | PCI device enumeration, drivers | ✅ Implemented |
| `smartctl.sh` | smartmontools | SMART drive health, NVMe status | ✅ Implemented |

### GPU-Specific Tools

| Module | Tool | Purpose | Status |
|--------|------|---------|--------|
| `nvidia.sh` | nvidia-smi | NVIDIA GPU metrics, VRAM, clocks | ✅ Implemented |
| `amd.sh` | lm-sensors + sysfs | AMD GPU metrics, VRAM, power | ✅ Implemented |

### Hardware Information Tools

| Module | Tool | Purpose | Status |
|--------|------|---------|--------|
| `hdparm.sh` | hdparm | Disk parameters, model, serial | ✅ Implemented |
| `dmidecode.sh` | dmidecode | BIOS, motherboard, memory info | ✅ Implemented |
| `power.sh` | acpi/upower | Battery status, AC power, thermals | ✅ Implemented |

---

## Planned CLI Tools

Future modules to expand hardware and system monitoring capabilities.

### Priority 1: Commonly Used Tools

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `lsusb.sh` | usbutils | USB device enumeration | `lsusb_available`, `lsusb_get_devices`, `lsusb_get_device_info` |
| `nmcli.sh` | NetworkManager | Connection management | `nmcli_available`, `nmcli_get_connections`, `nmcli_get_wifi_list` |
| `iw.sh` | iw | WiFi details (extend network.sh) | `iw_available`, `iw_get_station_info`, `iw_get_channel` |

### Priority 2: Display and Audio

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `display.sh` | xrandr/wlr-randr | Monitor info, resolution | `display_available`, `display_get_monitors`, `display_get_resolution` |
| `audio.sh` | pactl/wpctl | PulseAudio/PipeWire sinks | `audio_available`, `audio_get_sinks`, `audio_get_sources`, `audio_get_volume` |
| `bluetooth.sh` | bluetoothctl | Bluetooth devices | `bluetooth_available`, `bluetooth_get_devices`, `bluetooth_is_connected` |

### Priority 3: System Services

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `systemd.sh` | systemctl | Service status | `systemd_is_active`, `systemd_get_status`, `systemd_list_failed` |
| `journalctl.sh` | journalctl | Log querying | `journalctl_get_recent`, `journalctl_get_boot_errors` |

### Priority 4: Network Deep-Dive

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `ethtool.sh` | ethtool | NIC capabilities | `ethtool_available`, `ethtool_get_speed`, `ethtool_get_driver_info` |
| `ss.sh` | ss/netstat | Socket statistics | `ss_get_listening`, `ss_get_connections` |

### Priority 5: Containers and Virtualization

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `containers.sh` | docker/podman | Container status | `containers_available`, `containers_list`, `containers_get_stats` |
| `libvirt.sh` | virsh | VM status | `libvirt_available`, `libvirt_list_domains`, `libvirt_get_domain_info` |

### Priority 6: Graphics Deep-Dive

| Module | Tool | Purpose | Functions |
|--------|------|---------|-----------|
| `glxinfo.sh` | glxinfo | OpenGL renderer info | `glxinfo_available`, `glxinfo_get_renderer`, `glxinfo_get_version` |
| `vulkaninfo.sh` | vulkaninfo | Vulkan GPU info | `vulkaninfo_available`, `vulkaninfo_get_devices` |

---

## Module Implementation Guidelines

When implementing new CLI tool modules, follow these conventions:

### File Structure
```bash
#!/usr/bin/env bash
# modulename.sh - Brief description
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_MODULENAME_LOADED:-}" ]] && return 0
_SYSTEM_MODULENAME_LOADED=1

# Check if tool is installed
# Usage: modulename_available && echo "tool installed"
modulename_available() {
    command -v toolname &>/dev/null
}

# Function implementations...
```

### Naming Conventions
- **Guard variable:** `_SYSTEM_<MODULE>_LOADED`
- **Availability check:** `<module>_available()`
- **Getters:** `<module>_get_<thing>()`
- **Checks:** `<module>_is_<condition>()`
- **Combined info:** `<module>_get_<thing>_info()` returning `"field1|field2|field3"`

### Return Values
- Return empty string on failure (not error text)
- Return `-` for missing fields in combined outputs
- Use availability checks before tool execution
- Silent failure for optional features

### Test File
```bash
#!/usr/bin/env bash
# test_modulename.sh - Unit tests for modulename.sh

test_file_start "modulename.sh"
source "$PROJECT_DIR/lib/mod/hw/modulename.sh"

assert_var_defined "_SYSTEM_MODULENAME_LOADED"
assert_function_exists "modulename_available"
assert_function_exists "modulename_get_something"

# Test availability
if modulename_available; then
    echo "  ${GREEN}✓${RESET} modulename_available detected tool"
else
    echo "  ${YELLOW}⚠${RESET} tool not installed (skipping live tests)"
fi

# Test empty arg handling
result=$(modulename_get_something "")
assert_eq "" "$result" "modulename_get_something with empty arg returns empty"
```

---

## Feature Requests

Have a CLI tool you'd like to see integrated? Consider:

1. **Utility:** How commonly is this tool used?
2. **Portability:** Is it available across distributions?
3. **Output format:** Can output be reliably parsed?
4. **Root requirement:** Does it need sudo?

Open an issue or submit a PR following the module implementation guidelines above.

---

## Version History

### v1.0.1 (Current)
- Fix: LICENSE corrected to Apache 2.0
- Fix: Terminal detection logic (_is_full_terminal AND→OR)
- Fix: Logging guard ordering and pipe exit code propagation (PIPESTATUS)
- Fix: format_bytes inconsistent return format (int vs float)
- Fix: Text width cache key collision, truncate_visual ANSI preservation
- Fix: Sensors cache auto-refresh (5s TTL), storage.sh jq dependency check
- Fix: fzf.sh warns on preview fallback, viewer.sh pipe error handling
- Fix: Stale source paths in README, docs, and code comments
- Fix: Misleading test_file_start names, test_emojis.sh converted to unit test
- Fix: Dashboard parallel timing test made non-critical
- Added missing test assertions (log_silent, log_time, UI behavioral tests)
- Documentation accuracy pass across all docs

### v1.0.0
- Initial release
- Core modules: colors, cursor, spinner, logging, sudo
- UI modules: base, input, format, table, progress, gauge, storage, network
- System modules: base, inxi, cpu, memory, storage, gpu, network
- CLI tools: sensors, lspci, smartctl, nvidia, amd, hdparm, dmidecode, power
- Dashboard and runner modules
- 5 example scripts
- Comprehensive documentation
