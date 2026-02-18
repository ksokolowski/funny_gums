# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Licensing & Ownership (CRITICAL)

**NEVER add AI attribution to commits:**
- No "Generated with Claude", "Co-Authored-By: Claude", or similar
- No AI tool mentions in commit messages, comments, or documentation
- Current regulations treat AI as an advanced tool (like a compiler), not an author

**NEVER modify licensing:**
- Project uses Apache 2.0 license (defined in project files)
- Do not add, modify, or create LICENSE files
- Do not add licensing statements to code or documentation

**Why this matters:**
- Only humans can legally be authors of code or creative work
- Code with uncertain authorship may be treated as public domain
- AI attribution can affect legal status and may require project deletion

## Build and Test Commands

```bash
make check                        # Run lint + format-check + tests (mirrors CI)
make test                         # Run all tests
make test-ui                      # Run specific test file (test_ui.sh)
make lint                         # Run shellcheck only
make format                       # Auto-format all scripts with shfmt
make format-check                 # Check formatting without applying changes
```

Or directly:
```bash
./tests/run_tests.sh              # Run all tests (includes shellcheck)
./tests/run_tests.sh test_ui.sh   # Run specific test file
shellcheck --severity=error funny_gums.sh lib/**/*.sh examples/*.sh tests/*.sh
```

## Local CI Setup

```bash
make setup                        # Configure git hooks + check dependencies
make deps                         # Check dependencies only
```

After setup, `shellcheck`, `shfmt`, and tests run automatically on every commit.

**Always run `make check` before pushing** to avoid CI failures.

## Architecture

This is a modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

**Entry point:** `funny_gums.sh` sources all modules in dependency order.

**Directory structure:**
```
lib/
├── core/               # Foundation modules (no dependencies)
│   ├── sh/             # Shell utilities
│   │   ├── deps.sh     # Dependency checking (dep_require_all)
│   │   ├── gum_wrapper.sh  # Gum abstraction layer
│   │   ├── http.sh     # HTTP helpers
│   │   ├── logging.sh  # Logging with gum
│   │   └── sudo.sh     # Sudo helpers
│   ├── term/           # Terminal handling
│   │   ├── colors.sh   # ANSI color definitions
│   │   ├── cursor.sh   # Cursor control
│   │   └── terminal.sh # Terminal capability detection (3-tier)
│   └── text/           # Text/emoji processing
│       ├── emoji_data.sh       # Emoji width tables, VS16/ZWJ detection
│       ├── emoji_registry.sh   # VS16 emoji registry with fallbacks
│       ├── emoji_width_hybrid.sh
│       ├── emojis.sh           # Semantic emoji constants (auto-adapts)
│       └── text.sh             # Visual width calculation, padding
│
├── ui/                 # UI component modules
│   ├── interaction/    # Input handling
│   │   ├── fzf.sh      # fzf-based selection (degrades gracefully)
│   │   └── input.sh    # Input, choose, confirm, filter, file
│   ├── layout/         # Layout components
│   │   ├── base.sh     # Box, success, error, warn, info
│   │   ├── format.sh   # Format, code, emoji, template
│   │   └── ui.sh       # Loader (sources all ui/layout/*.sh)
│   └── widgets/        # UI widgets
│       ├── gauge.sh    # Progress bars, minibars, status
│       ├── progress.sh # Spin, join functions
│       ├── spinner.sh  # Spinner animation
│       ├── table.sh    # Table functions
│       └── viewer.sh   # Pager/viewer (degrades if bat/less missing)
│
├── mod/                # System/hardware query modules
│   ├── hw/             # Hardware metrics
│   │   ├── amd.sh      # AMD GPU queries
│   │   ├── cpu.sh      # CPU metrics (usage, temp, freq, load)
│   │   ├── gpu.sh      # GPU temperature
│   │   ├── memory.sh   # Memory/swap metrics
│   │   ├── nvidia.sh   # NVIDIA GPU queries
│   │   └── sensors.sh  # Thermal sensors
│   ├── net/            # Network
│   │   ├── network.sh  # Network interfaces, wifi signal
│   │   └── ui.sh       # Network UI components
│   ├── os/             # OS/system queries
│   │   ├── base.sh     # format_bytes, format_kb
│   │   ├── dmidecode.sh # DMI/hardware info
│   │   ├── inxi.sh     # Inxi caching and CSV parsers
│   │   ├── lspci.sh    # PCI device queries
│   │   ├── power.sh    # Power management
│   │   └── system.sh   # Loader (sources all mod/os/*.sh)
│   └── storage/        # Storage
│       ├── hdparm.sh   # Drive performance
│       ├── smartctl.sh # Drive health monitoring
│       ├── storage.sh  # Drive enumeration, partitions, disk usage
│       └── ui.sh       # Partition bar, drive layout, fs legend
│
└── app/                # Orchestration modules
    ├── dashboard.sh    # Step-based dashboard UI
    └── runner.sh       # Command execution with dashboard
```

**Module dependency chain:**
- Level 0: `lib/core/*` (no dependencies)
- Level 1: `lib/ui/*` (depends on core/term/colors)
- Level 1: `lib/app/*` (depends on core/term/colors, cursor, widgets/spinner)
- Level 2: `lib/mod/*` (depends on core for ANSI and formatting)

**Sourceable module pattern:** Each module uses a guard pattern:
```bash
[[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0
_MODULE_SH_LOADED=1
```

**Selective sourcing:** Source only what you need:
```bash
source lib/core/term/colors.sh      # Just colors
source lib/ui/layout/ui.sh          # All layout UI components
source lib/mod/hw/cpu.sh            # Just CPU metrics
source lib/mod/os/system.sh         # All OS/system metrics
```

## Code Conventions

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -uo pipefail` (not `-e` for test scripts)
- Quote variables: `"$var"` not `$var`
- Use `$'\e[...'` syntax for ANSI escapes
- Portable path resolution: `_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Function naming:**
- Module-prefixed: `dashboard_init()`, `spinner_set()`, `ui_box()`
- Extended variants with `_ext` suffix: `ui_input_ext()`, `ui_write_ext()`
- Private helpers with `_` prefix: `_ui_build_bar()`, `_ui_threshold_color()`

**Variable naming:**
- UPPER_SNAKE_CASE for exported/global: `DASHBOARD_STEPS`, `LOG_FILE`
- Module prefix for globals: `SPINNER_IDX`, `RUNNER_CMD_PID`

## Test Framework

Test assertions defined in `tests/framework.sh`:
- `assert_eq "expected" "actual" "message"`
- `assert_contains "haystack" "needle" "message"`
- `assert_not_empty "$value" "message"`
- `assert_success command args...`
- `assert_fails command args...`
- `assert_function_exists "function_name"`
- `assert_var_defined "VAR_NAME"`

Test file structure:
```bash
test_file_start "module_name.sh"
source "$PROJECT_DIR/lib/core/module_name.sh"
assert_function_exists "function_name"
```

## Adding New Modules

**Adding to existing domain (e.g., new hardware module):**
1. Create `lib/mod/hw/newmodule.sh` with guard pattern
2. Add functions with appropriate prefix
3. Add source line to `lib/mod/os/system.sh` loader (or relevant domain loader)
4. Create `tests/test_newmodule.sh`

**Adding new domain (e.g., lib/audio/):**
1. Create `lib/audio/` directory
2. Create submodules with guard patterns
3. Create a loader `lib/audio/audio.sh` that sources submodules
4. Add source line to `funny_gums.sh`
5. Create tests
