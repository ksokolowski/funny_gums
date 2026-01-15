# my_gums - Copilot Instructions

A modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

## Architecture

The library uses a **sourceable module pattern**—each file in `lib/` is an independent module with:
- Guard pattern to prevent multiple sourcing: `[[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0`
- Self-contained dependencies via `_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Entry point:** [my_gums.sh](my_gums.sh) sources all modules in dependency order.

**Core modules:**
- [colors.sh](lib/colors.sh) - ANSI color variables and `colorize()` helper
- [cursor.sh](lib/cursor.sh) - Terminal cursor control (save/restore, movement, clearing)
- [spinner.sh](lib/spinner.sh) - Multiple spinner animation presets (dots, braille, emoji)
- [logging.sh](lib/logging.sh) - Structured logging via `gum log` with file output
- [ui.sh](lib/ui.sh) - High-level UI wrappers (`ui_box`, `ui_confirm`, `ui_choose`, etc.)
- [dashboard.sh](lib/dashboard.sh) - Multi-step progress dashboard with in-place updates
- [runner.sh](lib/runner.sh) - Command execution with spinner/dashboard integration
- [sudo.sh](lib/sudo.sh) - Sudo credential management with keepalive

**Dependency chain:** `runner.sh` → `dashboard.sh` → `spinner.sh`, `cursor.sh`, `colors.sh`

## Code Conventions

### Shell Style
- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -uo pipefail` (not `-e` for test scripts)
- Use `shellcheck` directives when needed: `# shellcheck disable=SC2034`
- Quote variables: `"$var"` not `$var`
- Use `$'\e[...'` syntax for ANSI escapes
- Portable path resolution: `_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

### Function Naming
- Module-prefixed: `dashboard_init()`, `spinner_set()`, `ui_box()`
- Usage documented in comments above each function

### Variable Naming
- UPPER_SNAKE_CASE for exported/global: `DASHBOARD_STEPS`, `LOG_FILE`
- Module prefix for globals: `SPINNER_IDX`, `RUNNER_CMD_PID`

## Testing

Run tests from project root:
```bash
./tests/run_tests.sh              # Run all tests
./tests/run_tests.sh test_ui.sh   # Run specific test file
```

**Test framework** (defined in [tests/framework.sh](tests/framework.sh)):
- `assert_eq "expected" "actual" "message"`
- `assert_not_empty "$value" "message"`
- `assert_success command args...`
- `assert_fails command args...`
- `assert_function_exists "function_name"`
- `assert_var_defined "VAR_NAME"`

**Test file structure:**
```bash
test_file_start "module_name.sh"
source "$PROJECT_DIR/lib/module_name.sh"
assert_function_exists "function_name"
# ... assertions
```

CI runs `shellcheck --severity=error` on all scripts and executes the test suite.

## Adding New Modules

1. Create `lib/newmodule.sh` with guard pattern
2. Add functions with `newmodule_` prefix
3. Create `tests/test_newmodule.sh` following existing patterns
4. Add to [my_gums.sh](my_gums.sh) in correct dependency order

## External Dependencies

- **gum** (required): Used by `ui.sh`, `logging.sh`, `dashboard.sh` for styled terminal output
- **tput**: Used by `cursor.sh` for cursor visibility control
- **shellcheck**: Used by test suite and CI for linting
