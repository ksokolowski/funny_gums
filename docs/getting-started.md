# Getting Started

This guide will help you set up Funny Gums and write your first terminal UI script.

## Prerequisites

### Required: gum

Funny Gums requires [gum](https://github.com/charmbracelet/gum), a terminal UI toolkit from Charm.

**Installation:**

```bash
# macOS (Homebrew)
brew install gum

# Arch Linux
pacman -S gum

# Debian/Ubuntu (via Charm apt repo)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# From source
go install github.com/charmbracelet/gum@latest
```

### Optional: System Monitoring Tools

For full functionality of the system monitoring modules:

```bash
# Debian/Ubuntu
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
source /path/to/funny_gums/lib/core/colors.sh
echo "${GREEN}Success!${RESET}"

# UI components
source /path/to/funny_gums/lib/ui/ui.sh
result=$(ui_choose "Option 1" "Option 2" "Option 3")

# System metrics
source /path/to/funny_gums/lib/system/cpu.sh
temp=$(get_cpu_temp)
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
cpu_temp=$(get_cpu_temp)
cpu_usage=$(get_cpu_usage)

# Get memory info
mem_info=$(get_memory_info)
mem_used=$(echo "$mem_info" | cut -d'|' -f1)
mem_total=$(echo "$mem_info" | cut -d'|' -f2)
mem_pct=$(echo "$mem_info" | cut -d'|' -f3)

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
./tests/run_tests.sh test_cpu.sh

# Lint all scripts manually
shellcheck --severity=error lib/**/*.sh
```

## Next Steps

- Read the [Architecture](architecture.md) guide to understand module relationships
- Explore the [API Reference](api/core.md) for detailed function documentation
- Check out the [Examples](examples.md) for real-world usage patterns
- See the [Roadmap](roadmap.md) for planned features
