# Funny Gums - Copilot Instructions

A modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

## Architecture

The library uses a **sourceable module pattern**—each file in `lib/` is an independent module with:
- Guard pattern to prevent multiple sourcing: `[[ -n "${_MODULE_SH_LOADED:-}" ]] && return 0`
- Self-contained dependencies via `_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

**Entry point:** [funny_gums.sh](funny_gums.sh) sources all modules in dependency order.

**Directory structure:**
```
lib/
├── core/           # Foundation modules (no dependencies)
│   ├── colors.sh   # ANSI color variables and colorize() helper
│   ├── cursor.sh   # Terminal cursor control
│   ├── spinner.sh  # Spinner animation presets
│   ├── logging.sh  # Structured logging via gum log
│   └── sudo.sh     # Sudo credential management
├── ui/             # UI component modules
│   ├── ui.sh       # Loader (sources all ui/*.sh)
│   └── ...
├── system/         # Hardware/system query modules
│   ├── system.sh   # Loader (sources all system/*.sh)
│   └── ...
└── dashboard/      # Orchestration modules
    ├── dashboard.sh
    └── runner.sh
```

**Dependency chain:** `runner.sh` → `dashboard.sh` → `spinner.sh`, `cursor.sh`, `colors.sh`

## Code Conventions

### Shell Style
- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -uo pipefail` (not `-e` for test scripts)
- Use `shellcheck` directives when needed: `# shellcheck disable=SC2034`
- Quote variables: `"$var"` not `$var`
- Use `$'\e[...'` syntax for ANSI escapes
- Portable path resolution: `_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- For symlink support in scripts: use `readlink` loop pattern (see examples)

### Function Naming
- Module-prefixed: `dashboard_init()`, `spinner_set()`, `ui_box()`
- Extended variants with `_ext` suffix: `ui_input_ext()`, `ui_write_ext()`
- Usage documented in comments above each function

### Variable Naming
- UPPER_SNAKE_CASE for exported/global: `DASHBOARD_STEPS`, `LOG_FILE`
- Module prefix for globals: `SPINNER_IDX`, `RUNNER_CMD_PID`

## Gum Command Coverage

| Gum Command | Wrapper Functions |
|-------------|-------------------|
| `gum style` | `ui_box`, `ui_success`, `ui_error`, `ui_warn`, `ui_info` |
| `gum confirm` | `ui_confirm` |
| `gum choose` | `ui_choose`, `ui_choose_multi`, `ui_choose_limit`, `ui_choose_selected` |
| `gum input` | `ui_input`, `ui_password`, `ui_input_ext`, `ui_input_header` |
| `gum write` | `ui_write`, `ui_write_ext` |
| `gum filter` | `ui_filter`, `ui_filter_header` |
| `gum file` | `ui_file`, `ui_dir`, `ui_file_all` |
| `gum spin` | `ui_spin`, `ui_spin_type`, `ui_spin_output` |
| `gum table` | `ui_table`, `ui_table_file`, `ui_table_columns` |
| `gum pager` | `ui_pager`, `ui_pager_numbered`, `ui_pager_wrap` |
| `gum format` | `ui_format`, `ui_format_code`, `ui_format_emoji` |
| `gum join` | `ui_join_h`, `ui_join_v` |
| `gum log` | `log_info`, `log_warn`, `log_error`, `log_structured`, `log_fatal` |

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
source "$PROJECT_DIR/lib/core/module_name.sh"
assert_function_exists "function_name"
# ... assertions
```

CI runs `shellcheck --severity=error` on all scripts and executes the test suite.

## Adding New Modules

1. Create `lib/domain/newmodule.sh` with guard pattern
2. Add functions with `newmodule_` prefix
3. Add source line to domain loader (e.g., `lib/ui/ui.sh`)
4. Create `tests/test_newmodule.sh` following existing patterns
5. If new domain, add to [funny_gums.sh](funny_gums.sh)

## Example Scripts

| Script | Features Demonstrated |
|--------|----------------------|
| [openrgb_fix.sh](examples/openrgb_fix.sh) | Dashboard, runner, multi-step progress |
| [git_commit.sh](examples/git_commit.sh) | `ui_choose`, `ui_input`, `ui_write`, `ui_confirm` |
| [csv_viewer.sh](examples/csv_viewer.sh) | `ui_table`, `ui_filter`, `ui_pager` |
| [markdown_preview.sh](examples/markdown_preview.sh) | `ui_format`, `ui_pager`, `ui_file` |
| [system_dashboard.sh](examples/system_dashboard.sh) | `ui_table`, `ui_spin_type`, `log_structured` |

## External Dependencies

- **gum** (required): Used by `ui.sh`, `logging.sh`, `dashboard.sh` for styled terminal output
- **tput**: Used by `cursor.sh` for cursor visibility control
- **shellcheck**: Used by test suite and CI for linting
