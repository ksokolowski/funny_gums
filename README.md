# Funny Gums

[![Tests](https://github.com/ksokolowski/funny_gums/actions/workflows/test.yml/badge.svg)](https://github.com/ksokolowski/funny_gums/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum) from [Charm](https://charm.sh).

## Features

- 🎨 **Colors** - ANSI color variables and helper functions
- 📍 **Cursor** - Terminal cursor control (movement, visibility, clearing)
- 🔄 **Spinner** - Multiple animation presets + native gum spin integration
- 📝 **Logging** - Structured logging with `gum log` integration
- 🖼️ **UI** - High-level wrappers for boxes, confirms, inputs, selections, tables, and pagers
- 📊 **Dashboard** - Multi-step progress dashboard with in-place updates
- 🏃 **Runner** - Command execution with spinner/dashboard integration
- 🔐 **Sudo** - Credential management with keepalive
- 🎯 **Terminal-Aware Emojis** - 3-tier system with automatic VS16 fallbacks for GNOME Terminal
- 🖥️ **System Monitoring** - CPU, memory, storage, GPU, and network metrics

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
git clone https://github.com/ksokolowski/funny_gums.git
```

## Usage

### Source all modules at once
```bash
source /path/to/funny_gums/funny_gums.sh
```

### Source individual modules
```bash
source /path/to/funny_gums/lib/core/colors.sh
source /path/to/funny_gums/lib/ui/ui.sh
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

# Spinner with native gum types
ui_spin_type dot "Loading..." sleep 2
ui_spin_type moon "Processing..." my_command

# Tables and pagers
cat data.csv | ui_table
cat README.md | ui_format | ui_pager

# Logging (including structured)
log_init "/tmp/myapp.log"
log_info "Application started"
log_structured info "Processing" file "data.csv" rows 100
```

## Examples

| Script | Description |
|--------|-------------|
| [openrgb_fix.sh](examples/openrgb_fix.sh) | Multi-step dashboard with progress tracking |
| [git_commit.sh](examples/git_commit.sh) | Interactive conventional commit helper |
| [csv_viewer.sh](examples/csv_viewer.sh) | CSV data explorer with table/filter |
| [markdown_preview.sh](examples/markdown_preview.sh) | Markdown file preview |
| [system_dashboard.sh](examples/system_dashboard.sh) | System info dashboard |

## Terminal-Aware Emoji System

VS16 emojis (like ⚠️ ⚙️ 🌡️) cause alignment issues in GNOME Terminal and other VTE-based terminals. The library automatically detects terminal capability and provides appropriate fallbacks:

| Terminal Tier | Examples | Emoji Handling |
|---------------|----------|----------------|
| **full** | Kitty, WezTerm, Ghostty, iTerm | Full VS16 support |
| **compatible** | GNOME Terminal, Tilix | Colorful fallbacks (🟡 instead of ⚠️) |
| **legacy** | xterm, TTY | Text fallbacks (`[!]` instead of ⚠️) |

**Usage:** Simply use the `$EMOJI_*` variables - they auto-adapt to the terminal:

```bash
source lib/core/emojis.sh

echo "$EMOJI_WARNING Config missing"   # ⚠️ or 🟡 or [!]
echo "$EMOJI_CPU Processing..."        # ⚙️ or 🔧 or [*]
echo "$EMOJI_SUCCESS Done!"            # ✅ (works everywhere)
```

## API Reference

### UI Functions

| Function | Description |
|----------|-------------|
| `ui_box` | Styled box with rounded border |
| `ui_confirm` | Yes/No confirmation dialog |
| `ui_choose` | Single choice selection |
| `ui_choose_multi` | Multi-choice selection |
| `ui_choose_limit N` | Select up to N items |
| `ui_input` | Single-line text input |
| `ui_password` | Password input |
| `ui_write` | Multi-line text input |
| `ui_filter` | Fuzzy filter from list |
| `ui_file` | File picker |
| `ui_dir` | Directory picker |
| `ui_table` | Interactive table display |
| `ui_pager` | Scrollable text viewer |
| `ui_format` | Render markdown |
| `ui_format_code` | Syntax highlight code |
| `ui_spin` | Spinner while command runs |
| `ui_spin_type TYPE` | Spinner with type (dot, moon, globe, etc.) |
| `ui_join_h` / `ui_join_v` | Join text horizontally/vertically |

### Logging Functions

| Function | Description |
|----------|-------------|
| `log_info` | Info level log |
| `log_warn` | Warning level log |
| `log_error` | Error level log |
| `log_debug` | Debug level (when VERBOSE=true) |
| `log_structured` | Key-value structured logging |
| `log_fatal` | Fatal error (exits script) |

## Project Structure

```
funny_gums/
├── funny_gums.sh       # Entry point - sources all modules
├── lib/
│   ├── core/           # Foundation modules
│   │   ├── colors.sh   # ANSI color variables
│   │   ├── cursor.sh   # Cursor control functions
│   │   ├── spinner.sh  # Spinner animation presets
│   │   ├── logging.sh  # Structured logging
│   │   └── sudo.sh     # Sudo management
│   ├── ui/             # UI component modules
│   │   ├── ui.sh       # Loader for all UI modules
│   │   ├── base.sh     # Box, success, error, warn, info
│   │   ├── input.sh    # Input, choose, confirm
│   │   ├── gauge.sh    # Progress bars, minibars
│   │   └── ...
│   ├── system/         # System monitoring modules
│   │   ├── system.sh   # Loader for all system modules
│   │   ├── cpu.sh      # CPU metrics
│   │   ├── memory.sh   # Memory metrics
│   │   └── ...
│   └── dashboard/      # Dashboard modules
│       ├── dashboard.sh
│       └── runner.sh
├── examples/           # Example scripts
└── tests/              # Test suite
```

## Testing

```bash
./tests/run_tests.sh              # Run all tests
./tests/run_tests.sh test_ui.sh   # Run specific test
```

## VS16 Emoji Support

Funny Gums includes proper handling for VS16 (Variation Selector 16) emojis like ⚙️, ▶️, and ZWJ sequences like 👨‍💻. The library automatically detects modern terminals and calculates correct visual widths for emoji-aware text processing.

```bash
source lib/core/text.sh
detect_terminal_mode          # Detects "modern" or "legacy"
visual_width "Hello ⚙️"       # Returns: 9 (5 + 1 + 2 + VS16)
pad_visual "✅ Done" 15       # Pads to visual width 15
```

Modern terminals supported: Kitty, WezTerm, iTerm, Alacritty, Ghostty, GNOME Terminal 6003+

## Built on Charm

This library is powered by [gum](https://github.com/charmbracelet/gum), part of the excellent [Charm](https://charm.sh) ecosystem of Go-based terminal tools:

- **[gum](https://github.com/charmbracelet/gum)** - A tool for glamorous shell scripts
- **[bubbletea](https://github.com/charmbracelet/bubbletea)** - TUI framework for Go
- **[lipgloss](https://github.com/charmbracelet/lipgloss)** - Style definitions for terminal apps
- **[bubbles](https://github.com/charmbracelet/bubbles)** - TUI components for bubbletea

## License

MIT License - see [LICENSE](LICENSE) for details.
