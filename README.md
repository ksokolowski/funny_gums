<table>
  <tr>
    <td valign="top">
      <h1>Funny Gums 🚀</h1>
      <p><strong>Modular, Hierarchical Bash Library for Stunning Terminal UIs.</strong></p>
      <p>Funny Gums is a professional-grade Bash toolkit designed to build complex, responsive, and visually rich terminal applications. It bridges the gap between simple shell scripts and full-blown TUIs by providing a layered architecture powered by <a href="https://github.com/charmbracelet/gum">gum</a>.</p>
      <h3>Key Features ✨</h3>
      <ul>
        <li>🧱 <strong>3-Tier Architecture</strong>: Core foundational utilities, generic UI widgets, and domain-specific system modules.</li>
        <li>🎨 <strong>Rich Aesthetics</strong>: 256-color support, neon palettes, and curated visual styles.</li>
        <li>🧪 <strong>Robust Testing</strong>: 300+ automated unit tests ensuring stability across shell environments.</li>
        <li>🎭 <strong>Emoji Awareness</strong>: Sophisticated 3-tier emoji degradation logic (VS16/ZWJ support).</li>
        <li>⚙️ <strong>Hardware Metrics</strong>: Integrated wrappers for <code>inxi</code>, <code>nvidia-smi</code>, <code>smartctl</code>, and more.</li>
      </ul>
    </td>
    <td valign="top" width="350">
      <img src="assets/funny_gums.jpg" alt="Funny Gums Main Logo">
    </td>
  </tr>
</table>

## Quick Start 🏎️

### 1. Install Dependencies
Funny Gums requires `gum`. Most systems also benefit from `inxi` and `lm-sensors`.

```bash
# Ubuntu/Debian
sudo apt install gum inxi lm-sensors
```

### 2. Write Your First Script
```bash
#!/usr/bin/env bash
source ./funny_gums.sh

ui_box "Welcome" "Funny Gums is ready!"
cpu_temp=$(get_cpu_temp_live)
echo "Mainframe Temperature: ${cpu_temp}°C"
```

---

## Documentation 📖

| Resource | Description |
|----------|-------------|
| 📖 **[User Guide](docs/USER-GUIDE.md)** | Comprehensive reference for all modules. |
| 🚀 **[Getting Started](docs/GETTING-STARTED.md)** | Step-by-step installation and basic patterns. |
| 🏛️ **[Architecture](docs/ARCHITECTURE.md)** | Deep dive into the tiered design and dependency chain. |
| 💡 **[Examples](docs/EXAMPLES.md)** | Walkthroughs of the `examples/` directory. |

---

## Project Structure 📂

```text
lib/
├── core/ 🧱 - Foundation: Colors, Text, Logging, Sudo
├── ui/   📦 - Visualization: Boxes, Gauges, Tables, Inputs
├── mod/  ⚙️ - Domain: CPU, GPU, Storage, Network
└── app/  🏗️ - Logic: Dashboards and Command Runners
```

---

## License 📜
MIT License. See [LICENSE](LICENSE) for details.

[![Tests](https://github.com/ksokolowski/funny_gums/actions/workflows/test.yml/badge.svg)](https://github.com/ksokolowski/funny_gums/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/styledconsole)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/ksokolowski?label=Sponsor&logo=github)](https://github.com/sponsors/ksokolowski)

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
- **jq** - Required for efficient JSON parsing (system modules)
- **Standard Utils** - awk, sed, grep, date (usually pre-installed)

Install dependencies:
```bash
# Ubuntu / Debian
sudo apt install gum jq
```

## Installation

### 1. Clone the Repository

```bash
# Clone to your preferred location
git clone https://github.com/ksokolowski/funny_gums.git
cd funny_gums
```

### 2. Verify Dependencies

```bash
# Check if gum is available
which gum || echo "⚠️  gum not found - install it first!"

# Check if jq is available (needed for system modules)
which jq || echo "⚠️  jq not found - install it first!"
```

### 3. Try an Example

```bash
# Run a simple example to verify everything works
bash examples/markdown_preview.sh README.md
```

### 4. Use in Your Scripts

You have two options:

**Option A: Source everything** (easiest, loads all modules)
```bash
#!/usr/bin/env bash
source /path/to/funny_gums/funny_gums.sh

ui_box "Hello" "Funny Gums is ready!"
```

**Option B: Source specific modules** (faster, minimal footprint)
```bash
#!/usr/bin/env bash
source /path/to/funny_gums/lib/core/colors.sh
source /path/to/funny_gums/lib/ui/ui.sh

echo "${GREEN}Success!${RESET}"
ui_confirm "Continue?" && echo "Let's go!"
```

## Quick Examples

Common patterns and use cases:

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
log_fatal "Application stopped"
```

## Examples

<table>
  <tr>
    <td valign="top">
      <table>
        <thead>
          <tr>
            <th>Script</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><a href="examples/openrgb_fix.sh">openrgb_fix.sh</a></td>
            <td>Multi-step dashboard with progress tracking</td>
          </tr>
          <tr>
            <td><a href="examples/git_commit.sh">git_commit.sh</a></td>
            <td>Interactive conventional commit helper</td>
          </tr>
          <tr>
            <td><a href="examples/csv_viewer.sh">csv_viewer.sh</a></td>
            <td>CSV data explorer with table/filter</td>
          </tr>
          <tr>
            <td><a href="examples/markdown_preview.sh">markdown_preview.sh</a></td>
            <td>Markdown file preview</td>
          </tr>
          <tr>
            <td><a href="examples/system_dashboard.sh">system_dashboard.sh</a></td>
            <td>System info dashboard</td>
          </tr>
        </tbody>
      </table>
    </td>
    <td valign="top" width="200">
      <img src="assets/logo.png" alt="Funny Gums Secondary Logo">
    </td>
  </tr>
</table>

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
│   ├── core/           # Foundational utilities
│   │   ├── term/       # Colors, cursor, terminal
│   │   ├── text/       # Visual width, emojis
│   │   └── sh/         # Logging, sudo, deps
│   ├── ui/             # Visualization widgets
│   │   ├── layout/     # Core formatting, boxes
│   │   ├── widgets/    # Gauges, tables, spinners
│   │   └── interaction/ # Inputs, fuzzy select
│   ├── mod/            # Domain-specific modules
│   │   ├── hw/         # CPU, GPU, RAM, Sensors
│   │   ├── os/         # power, lspci, dmidecode
│   │   ├── storage/    # smartctl, hdparm
│   │   └── net/        # network info/ui
│   └── app/            # Application logic (Dashboard)
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

## Related Projects

If you work with Python, check out **[StyledConsole](https://github.com/ksokolowski/StyledConsole)** - a modern Python library for elegant terminal output with rich formatting, tables, panels, and gradients. It's like Funny Gums' sophisticated cousin for Python! 🐍✨

## Support

If you find Funny Gums useful, consider supporting its development:

| Platform        | Link                                                                       |
| --------------- | -------------------------------------------------------------------------- |
| GitHub Sponsors | [github.com/sponsors/ksokolowski](https://github.com/sponsors/ksokolowski) |
| Ko-fi           | [ko-fi.com/styledconsole](https://ko-fi.com/styledconsole)                 |

Your support helps maintain both Funny Gums and [StyledConsole](https://github.com/ksokolowski/StyledConsole)!

## License

MIT License - see [LICENSE](LICENSE) for details.
