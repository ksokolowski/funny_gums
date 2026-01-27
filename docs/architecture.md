# Architecture

This document describes the system design, module relationships, and patterns used in Funny Gums.

## Directory Structure

```
funny_gums/
├── funny_gums.sh           # Main entry point (sources all modules)
├── lib/
│   ├── core/               # Foundation modules (no dependencies)
│   │   ├── colors.sh       # ANSI color definitions
│   │   ├── cursor.sh       # Cursor control
│   │   ├── spinner.sh      # Spinner animation
│   │   ├── logging.sh      # Logging with gum
│   │   ├── sudo.sh         # Sudo helpers
│   │   ├── terminal.sh     # Terminal capability detection (3-tier)
│   │   ├── emoji_data.sh   # Emoji width tables and VS16/ZWJ detection
│   │   ├── emoji_registry.sh # VS16 emoji registry with fallbacks
│   │   ├── emojis.sh       # Semantic emoji constants
│   │   └── text.sh         # Visual width calculation
│   │
│   ├── ui/                 # UI component modules
│   │   ├── ui.sh           # Loader (sources all ui/*.sh)
│   │   ├── base.sh         # Box, success, error, warn, info
│   │   ├── input.sh        # Input, choose, confirm, filter, file
│   │   ├── format.sh       # Format, code, emoji, template
│   │   ├── table.sh        # Table, pager functions
│   │   ├── progress.sh     # Spin, join functions
│   │   ├── gauge.sh        # Progress bars, minibars, status
│   │   ├── storage.sh      # Partition bar, drive layout
│   │   └── network.sh      # Net status, interface line, wifi signal
│   │
│   ├── system/             # Hardware/system query modules
│   │   ├── system.sh       # Loader (sources all system/*.sh)
│   │   ├── base.sh         # format_bytes, format_kb
│   │   ├── inxi.sh         # Inxi caching and CSV parsers
│   │   ├── cpu.sh          # CPU metrics
│   │   ├── memory.sh       # Memory/swap metrics
│   │   ├── storage.sh      # Drive enumeration, partitions
│   │   ├── gpu.sh          # GPU temperature
│   │   ├── network.sh      # Network interfaces
│   │   ├── sensors.sh      # lm-sensors abstraction
│   │   ├── lspci.sh        # PCI device queries
│   │   ├── smartctl.sh     # Drive health (SMART + NVMe)
│   │   ├── nvidia.sh       # NVIDIA GPU queries
│   │   ├── amd.sh          # AMD GPU queries
│   │   ├── hdparm.sh       # Disk parameters
│   │   ├── dmidecode.sh    # BIOS/motherboard info
│   │   └── power.sh        # Battery/AC power
│   │
│   └── dashboard/          # Orchestration modules
│       ├── dashboard.sh    # Step-based dashboard UI
│       └── runner.sh       # Command execution with dashboard
│
├── tests/                  # Test files
│   ├── run_tests.sh        # Test runner
│   ├── framework.sh        # Test assertions
│   └── test_*.sh           # Individual test files
│
├── examples/               # Example scripts
│   ├── system_dashboard.sh
│   ├── csv_viewer.sh
│   ├── git_commit.sh
│   ├── markdown_preview.sh
│   └── openrgb_fix.sh
│
└── docs/                   # Documentation
    ├── README.md
    ├── getting-started.md
    ├── architecture.md
    ├── examples.md
    ├── roadmap.md
    └── api/
        ├── core.md
        ├── ui.md
        ├── system.md
        └── cli-tools.md
```

## Module Dependency Chain

```
Level 0: lib/core/*           (no dependencies)
    │
    ├── Level 1: lib/ui/*     (depends on core/colors)
    │
    ├── Level 1: lib/dashboard/*  (depends on core/colors, cursor, spinner)
    │
    └── Level 2: lib/system/* (depends on core/colors for ANSI functions)
```

### Core Modules (Level 0)
No dependencies on other Funny Gums modules. Can be sourced independently.

- `colors.sh` - ANSI color variables and `colorize()` helper
- `cursor.sh` - Terminal cursor manipulation
- `spinner.sh` - Spinner frame animations
- `logging.sh` - Structured logging via gum
- `sudo.sh` - Sudo credential management
- `terminal.sh` - Terminal capability detection (3-tier classification)
- `emoji_data.sh` - Emoji width tables, VS16/ZWJ detection
- `emoji_registry.sh` - VS16 emoji registry with automatic fallbacks
- `emojis.sh` - Semantic emoji constants (auto-adapts to terminal)
- `text.sh` - Visual width calculation, padding, truncation

### UI Modules (Level 1)
Depend on `core/colors.sh` for color support.

- `base.sh` - Styled boxes and messages
- `input.sh` - Interactive input dialogs
- `format.sh` - Text formatting and rendering
- `table.sh` - Tables and pagers
- `progress.sh` - Spinners and layout composition
- `gauge.sh` - Progress bars and gauges
- `storage.sh` - Storage visualization
- `network.sh` - Network interface visualization

### System Modules (Level 2)
Some depend on `core/colors.sh` for ANSI output.

- **Base:** `base.sh` (format_bytes), `inxi.sh` (caching)
- **Metrics:** `cpu.sh`, `memory.sh`, `storage.sh`, `gpu.sh`, `network.sh`
- **CLI Tools:** `sensors.sh`, `lspci.sh`, `smartctl.sh`, `nvidia.sh`, `amd.sh`, `hdparm.sh`, `dmidecode.sh`, `power.sh`

## Guard Pattern

Every module uses a guard pattern to prevent multiple sourcing:

```bash
#!/usr/bin/env bash
# module.sh - Module description
# shellcheck disable=SC2034

[[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0
_MODULE_SH_LOADED=1

# Module code here...
```

This ensures:
- Modules can be sourced multiple times safely
- Dependencies resolve correctly
- No duplicate function definitions

## Loader Pattern

Domain directories have loader files that source all submodules:

```bash
# lib/ui/ui.sh
[[ -n "${_UI_LOADED:-}" ]] && return 0
_UI_LOADED=1

_UI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$_UI_DIR/base.sh"
source "$_UI_DIR/input.sh"
source "$_UI_DIR/format.sh"
# ... more modules
```

## Selective Sourcing

For performance, source only what you need:

```bash
# Just colors (very lightweight)
source lib/core/colors.sh

# All UI components
source lib/ui/ui.sh

# Specific system module
source lib/system/cpu.sh

# All system modules
source lib/system/system.sh

# Everything
source funny_gums.sh
```

## Function Naming Conventions

### Public Functions
- **Module-prefixed:** `ui_box()`, `dashboard_init()`, `spinner_set()`
- **Extended variants:** `ui_input_ext()`, `ui_write_ext()` (more options)

### Private/Helper Functions
- **Underscore prefix:** `_ui_build_bar()`, `_ui_threshold_color()`

### System Getters
- **get_* pattern:** `get_cpu_temp()`, `get_memory_info()`
- **CLI tool prefixed:** `sensors_get_cpu_temp()`, `hdparm_get_model()`

## Variable Naming Conventions

### Global/Exported Variables
- **UPPER_SNAKE_CASE:** `LOG_FILE`, `VERBOSE`
- **Module prefix:** `SPINNER_IDX`, `RUNNER_CMD_PID`

### Local Variables
- **lower_snake_case:** `local temp_value`, `local bar_width`

## Path Resolution Pattern

Modules use portable path resolution to find their directory:

```bash
_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_MODULE_DIR/../core/colors.sh"
```

## Testing Pattern

Tests use the framework defined in `tests/framework.sh`:

```bash
#!/usr/bin/env bash
# test_module.sh - Unit tests for module.sh

test_file_start "module.sh"

source "$PROJECT_DIR/lib/path/module.sh"

# Test guard variable
assert_var_defined "_MODULE_LOADED"

# Test functions exist
assert_function_exists "module_function"

# Test function behavior
result=$(module_function "input")
assert_eq "expected" "$result" "Description of test"
```

## Adding New Modules

### To an Existing Domain

1. Create `lib/domain/newmodule.sh` with guard pattern
2. Add functions with appropriate prefix
3. Add `source` line to `lib/domain/domain.sh` loader
4. Create `tests/test_newmodule.sh`

### New Domain

1. Create `lib/newdomain/` directory
2. Create `lib/newdomain/newdomain.sh` loader
3. Create submodules with guard patterns
4. Add `source` line to `funny_gums.sh`
5. Create tests

## Error Handling

Functions follow these conventions:

- Return empty string on failure (not error text)
- Return `-` for missing/unavailable fields in combined output
- Use availability checks before calling tools: `tool_available || return 1`
- Silent failure for optional features

## Terminal-Aware Emoji System

The library includes a sophisticated emoji degradation system that ensures proper display across different terminal emulators.

### The VS16 Problem

VS16 (Variation Selector 16, U+FE0F) causes alignment issues in some terminals:

```
Problem in VTE terminals (GNOME Terminal, Tilix):
┌─────────────────────────────────────────┐
│  ⚠️ Warning message                      │  <- Border misaligned!
│  ✅ Success message                      │
└─────────────────────────────────────────┘
```

**Why it happens:**
- `gum` uses Go's `runewidth` library which calculates VS16 emoji width as **1**
- VTE terminals display VS16 emojis at width **2**
- This 1-character mismatch causes frame borders to shift

### 3-Tier Solution

The library detects terminal capability and selects appropriate emojis:

```
┌─────────────┬────────────────────────────────┬─────────────────────┐
│ Tier        │ Terminals                      │ Emoji Handling      │
├─────────────┼────────────────────────────────┼─────────────────────┤
│ full        │ Kitty, WezTerm, Ghostty,       │ Full VS16 support   │
│             │ iTerm, Alacritty, Win Terminal │                     │
├─────────────┼────────────────────────────────┼─────────────────────┤
│ compatible  │ GNOME Terminal, Tilix,         │ Colorful fallbacks  │
│             │ Terminator (VTE-based)         │ (no VS16)           │
├─────────────┼────────────────────────────────┼─────────────────────┤
│ legacy      │ xterm, TTY, older terminals    │ Text fallbacks      │
└─────────────┴────────────────────────────────┴─────────────────────┘
```

### Emoji Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  Script uses: $EMOJI_WARNING                                     │
│                    │                                             │
│                    ▼                                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  emoji_registry.sh detects TERMINAL_CAPABILITY          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                    │                                             │
│       ┌───────────┼───────────┐                                 │
│       ▼           ▼           ▼                                 │
│   ┌───────┐  ┌─────────┐  ┌────────┐                           │
│   │ full  │  │compatible│  │ legacy │                           │
│   │  ⚠️   │  │   🟡    │  │  [!]   │                           │
│   └───────┘  └─────────┘  └────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

### Semantic Fallbacks

VS16 emojis map to semantically similar colorful alternatives:

| Original | Compatible | Legacy | Semantic Meaning |
|----------|------------|--------|------------------|
| ⚠️ | 🟡 | `[!]` | Warning/caution (yellow) |
| ⚙️ | 🔧 | `[*]` | Settings/config |
| 🌡️ | 🔥 | `[T]` | Temperature/heat |
| 🖥️ | 💻 | `[S]` | Computer/server |
| ⏸️ | 🟠 | `\|\|` | Paused/waiting |
| 🗑️ | ❌ | `[X]` | Delete/remove |

### Best Practices for Scripts

**Use emoji variables, not hardcoded emojis:**

```bash
# Good - adapts to terminal
echo "$EMOJI_WARNING Configuration missing"
dashboard_add_step "$EMOJI_CPU" "Initialize CPU"

# Bad - may cause alignment issues in VTE
echo "⚙️ Processing..."
```

**For custom emojis, use the registry:**

```bash
# Get emoji appropriate for current terminal
icon=$(emoji "WARNING")

# Or check terminal capability
if [[ "$TERMINAL_CAPABILITY" == "full" ]]; then
    echo "Using fancy ZWJ emoji: 👨‍💻"
fi
```
