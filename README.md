# my_gums

A modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

## Features

- 🎨 **Colors** - ANSI color variables and helper functions
- 📍 **Cursor** - Terminal cursor control (movement, visibility, clearing)
- 🔄 **Spinner** - Multiple animation presets (dots, braille, emoji, moon, etc.)
- 📝 **Logging** - Structured logging with `gum log` integration
- 🖼️ **UI** - High-level wrappers for boxes, confirms, inputs, and selections
- 📊 **Dashboard** - Multi-step progress dashboard with in-place updates
- 🏃 **Runner** - Command execution with spinner/dashboard integration
- 🔐 **Sudo** - Credential management with keepalive

## Requirements

- **Bash** 4.0+
- **[gum](https://github.com/charmbracelet/gum)** - Required for UI components

Install gum:
```bash
# macOS
brew install gum

# Linux (Debian/Ubuntu)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

## Installation

Clone the repository:
```bash
git clone https://github.com/yourusername/my_gums.git
```

## Usage

### Source all modules at once
```bash
source /path/to/my_gums/my_gums.sh
```

### Source individual modules
```bash
source /path/to/my_gums/lib/colors.sh
source /path/to/my_gums/lib/ui.sh
```

### Quick examples

```bash
# Colors
echo "${RED}Error:${RESET} Something went wrong"
colorize "$GREEN" "Success!"

# UI components
ui_box "Welcome" "This is a styled box"
if ui_confirm "Continue?"; then
    echo "Proceeding..."
fi
choice=$(ui_choose "Option A" "Option B" "Option C")

# Spinner
spinner_set BRAILLE
while working; do
    spinner_tick
    sleep 0.1
done

# Logging
log_init "/tmp/myapp.log"
log_info "Application started"
log_warn "This is a warning"
log_error "Something failed"
```

See [examples/openrgb_fix.sh](examples/openrgb_fix.sh) for a complete usage example.

## Project Structure

```
my_gums/
├── my_gums.sh          # Entry point - sources all modules
├── lib/                # Library modules
│   ├── colors.sh       # ANSI color variables
│   ├── cursor.sh       # Cursor control functions
│   ├── spinner.sh      # Spinner animation presets
│   ├── logging.sh      # Structured logging
│   ├── ui.sh           # High-level gum wrappers
│   ├── dashboard.sh    # Progress dashboard
│   ├── runner.sh       # Command execution
│   └── sudo.sh         # Sudo management
├── examples/           # Example scripts
│   └── openrgb_fix.sh
└── tests/              # Test suite
    ├── framework.sh    # Test assertion functions
    ├── run_tests.sh    # Test runner
    └── test_*.sh       # Module tests
```

## Testing

```bash
./tests/run_tests.sh              # Run all tests
./tests/run_tests.sh test_ui.sh   # Run specific test
```

## License

MIT License - see [LICENSE](LICENSE) for details.
