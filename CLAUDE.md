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
./tests/run_tests.sh              # Run all tests (includes shellcheck)
./tests/run_tests.sh test_ui.sh   # Run specific test file
shellcheck --severity=error lib/**/*.sh  # Lint all scripts
```

## Architecture

This is a modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

**Entry point:** `funny_gums.sh` sources all modules in dependency order.

**Directory structure:**
```
lib/
├── core/           # Foundation modules (no dependencies)
│   ├── colors.sh   # ANSI color definitions
│   ├── cursor.sh   # Cursor control
│   ├── spinner.sh  # Spinner animation
│   ├── logging.sh  # Logging with gum
│   └── sudo.sh     # Sudo helpers
│
├── ui/             # UI component modules
│   ├── ui.sh       # Loader (sources all ui/*.sh)
│   ├── base.sh     # Box, success, error, warn, info
│   ├── input.sh    # Input, choose, confirm, filter, file
│   ├── format.sh   # Format, code, emoji, template
│   ├── table.sh    # Table, pager functions
│   ├── progress.sh # Spin, join functions
│   ├── gauge.sh    # Progress bars, minibars, status
│   ├── storage.sh  # Partition bar, drive layout, fs legend
│   └── network.sh  # Net status, interface line, wifi signal
│
├── system/         # Hardware/system query modules
│   ├── system.sh   # Loader (sources all system/*.sh)
│   ├── base.sh     # format_bytes, format_kb
│   ├── inxi.sh     # Inxi caching and CSV parsers
│   ├── cpu.sh      # CPU metrics (usage, temp, freq, load)
│   ├── memory.sh   # Memory/swap metrics
│   ├── storage.sh  # Drive enumeration, partitions, disk usage
│   ├── gpu.sh      # GPU temperature
│   └── network.sh  # Network interfaces, wifi signal
│
└── dashboard/      # Orchestration modules
    ├── dashboard.sh # Step-based dashboard UI
    └── runner.sh   # Command execution with dashboard
```

**Module dependency chain:**
- Level 0: `lib/core/*` (no dependencies)
- Level 1: `lib/ui/*` (depends on core/colors)
- Level 1: `lib/dashboard/*` (depends on core/colors, cursor, spinner)
- Level 2: `lib/system/*` (depends on core/colors for ANSI functions)

**Sourceable module pattern:** Each module uses a guard pattern:
```bash
[[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0
_MODULE_SH_LOADED=1
```

**Selective sourcing:** Source only what you need:
```bash
source lib/core/colors.sh           # Just colors
source lib/ui/ui.sh                 # All UI components
source lib/system/cpu.sh            # Just CPU metrics
source lib/system/system.sh         # All system metrics
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

**Adding to existing domain (e.g., new system module):**
1. Create `lib/system/newmodule.sh` with guard pattern
2. Add functions with appropriate prefix
3. Add source line to `lib/system/system.sh` loader
4. Create `tests/test_newmodule.sh`

**Adding new domain (e.g., lib/audio/):**
1. Create `lib/audio/` directory
2. Create `lib/audio/audio.sh` loader
3. Create submodules with guard patterns
4. Add source line to `funny_gums.sh`
5. Create tests

## Extensibility

The `lib/system/` folder is designed for additional hardware tools:
- `lspci.sh` - Direct lspci queries (PCI device details)
- `sensors.sh` - Direct sensors queries (all thermal data)
- `smartctl.sh` - Drive health monitoring
- `nvidia.sh` - NVIDIA GPU specific queries
- `amd.sh` - AMD GPU specific queries
