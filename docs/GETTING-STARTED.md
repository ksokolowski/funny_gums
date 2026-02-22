# Getting Started 🚀

This guide will help you set up Funny Gums and write your first terminal UI script.

## Prerequisites 🛠️

### Required Dependencies

Funny Gums requires the following core dependencies:

- **[gum](https://github.com/charmbracelet/gum)** - Terminal UI toolkit from Charm
- **jq** - JSON processor (used by system modules)
- **Bash 4.0+** and standard utils (awk, sed, grep, date, tput)

**Installation:**

```bash
# Ubuntu/Debian (via Charm apt repo - recommended)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum jq

# macOS (Homebrew)
brew install gum jq

# Arch Linux
pacman -S gum jq

# Fedora
sudo dnf install jq
# For gum on Fedora, see: https://github.com/charmbracelet/gum#installation

# From source (gum only)
go install github.com/charmbracelet/gum@latest
```

### Development Dependencies

If you plan to contribute to Funny Gums, install:

```bash
# Ubuntu/Debian
sudo apt install shellcheck shfmt

# macOS
brew install shellcheck shfmt

# Arch Linux
pacman -S shellcheck shfmt
```

### Optional: System Monitoring Tools

For full functionality of the system monitoring modules (`lib/mod/*`):

```bash
# Ubuntu/Debian
sudo apt install inxi lm-sensors smartmontools hdparm dmidecode acpi

# Arch Linux
sudo pacman -S inxi lm_sensors smartmontools hdparm dmidecode acpi

# Fedora
sudo dnf install inxi lm_sensors smartmontools hdparm dmidecode acpi
```

## Installation

Clone or download Funny Gums to your project:

```bash
git clone https://github.com/yourusername/funny_gums.git
cd funny_gums
```

Verify all dependencies are installed:

```bash
make deps
```

This will check for all required, development, and optional dependencies.

## Basic Usage

### Source Everything

```bash
#!/usr/bin/env bash
source /path/to/funny_gums/funny_gums.sh

# Now all modules are available
ui_box "Hello" "Welcome to Funny Gums!"
```

### Source Specific Modules

```bash
#!/usr/bin/env bash
# Only source what you need for smaller scripts

# Just colors
source /path/to/funny_gums/lib/core/term/colors.sh
echo "${GREEN}Success!${RESET}"

# UI components
source /path/to/funny_gums/lib/ui/layout/ui.sh
result=$(ui_choose "Option 1" "Option 2" "Option 3")

# System metrics
source /path/to/funny_gums/lib/mod/hw/cpu.sh
temp=$(get_cpu_temp_live)
echo "CPU Temperature: ${temp}°C"
```

## Your First Script

Create a simple system info script:

```bash
#!/usr/bin/env bash

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/funny_gums.sh"

# Show a styled box
ui_box "System Info" "Gathering system information..."

# Get CPU info
cpu_temp=$(get_cpu_temp_live)
cpu_usage=$(get_cpu_usage_live)

# Get memory info
read -r used_kb total_kb mem_pct <<< "$(get_memory_usage_live)"

# Display with colored gauges
echo ""
echo "CPU Temperature: ${cpu_temp:-N/A}°C"
ui_gauge_colored "$cpu_usage" 100 20 "CPU"
echo ""
ui_gauge_colored "$mem_pct" 100 20 "Memory"
echo ""
```

## Interactive Example

Create an interactive menu:

```bash
#!/usr/bin/env bash
source /path/to/funny_gums/funny_gums.sh

# Confirm action
if ui_confirm "Would you like to continue?"; then
    # Get user input
    name=$(ui_input "Enter your name")

    # Show selection menu
    color=$(ui_choose_with_header "Pick a color:" "Red" "Green" "Blue")

    # Display result in a styled box
    ui_success "Hello, $name!" "Your favorite color is: $color"
else
    ui_warn "Cancelled by user"
fi
```

## Running Examples

The `examples/` directory contains complete example scripts:

```bash
# System dashboard with live metrics
./examples/system_dashboard.sh

# CSV file viewer
./examples/csv_viewer.sh data.csv

# Interactive git commit helper
./examples/git_commit.sh

# Markdown preview
./examples/markdown_preview.sh README.md

# Multi-step task runner
./examples/openrgb_fix.sh
```

## Running Tests

Verify everything works:

```bash
# Run all tests (includes shellcheck)
./tests/run_tests.sh

# Run a specific test file
./tests/run_tests.sh test_text.sh

# Lint all scripts manually
shellcheck --severity=error lib/**/*.sh
```

## Next Steps

- Read the [Architecture](ARCHITECTURE.md) guide to understand module relationships
- Explore the **[User Guide](USER-GUIDE.md)** for a comprehensive reference (Core, UI, Modules).
- Check out the [Examples](EXAMPLES.md) for real-world usage patterns
- See the [Roadmap](ROADMAP.md) for planned features
