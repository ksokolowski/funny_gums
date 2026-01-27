# Funny Gums - Copilot Instructions

A modular Bash library providing terminal UI components powered by [gum](https://github.com/charmbracelet/gum).

## Architecture

The library uses a **sourceable module pattern**—each file in `lib/` is an independent module.

**Core Principles:**
- **Guard Pattern**: `[[ -n "${\_MODULE_SH_LOADED:-}" ]] && return 0` (prevent multiple sourcing).
- **Self-Contained**: Dependencies relative to `_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
- **Stateless**: Functions should prefer arguments over global state where possible.

**Directory Structure:**
```
lib/
├── core/           # Foundation (colors, cursor, logger, emojis, terminal detection)
├── ui/             # UI Wrappers (gum components: box, table, input)
├── dashboard/      # Orchestration (step-based runner, dashboard UI)
└── system/         # Hardware monitoring (cpu, mem, disk, network)
```

## Development Workflow

**Verification Commands:**
- **Full Check**: `make check` (Runs strict linting + all tests).
- **Lint Only**: `make lint` (Runs `shellcheck --severity=error`).
- **Test Only**: `make test` (Runs all tests).
- **Single Test**: `make test-ui` (Runs `tests/test_ui.sh`).

**Critical**: All scripts must pass `shellcheck` with zero errors.

## Code Conventions

### Shell Style
- **Shebang**: `#!/usr/bin/env bash`
- **Strict Mode**: `set -uo pipefail` (Use in all implementation files. Omit `-e` in tests).
- **Variable Quoting**: Always quote variables `"$var"`.
- **Path Resolution**:
  ```bash
  _DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ```

### Emoji & Formatting
**Do not hardcode emojis.** This project uses a smart capability detection system.
- Use constants from `lib/core/emojis.sh` (e.g., `${EMOJI_SUCCESS}`, `${EMOJI_WARNING}`).
- Examples: `${EMOJI_WAIT}` (hourglass), `${EMOJI_INFO}` (info symbol).
- This ensures automatic fallback for terminals lacking VS16/ZWJ support.

### Naming Patterns
- **Functions**: `namespace_action` (e.g., `ui_box`, `log_info`, `dashboard_render`).
- **Extended Variants**: `namespace_action_ext` (e.g., `ui_input_ext`).
- **Globals**: `UPPER_SNAKE_CASE` (e.g., `LOG_FILE`, `DASHBOARD_STEPS`).
- **Internal**: `_namespace_helper` (e.g., `_ui_cleanup`).

## Gum Wrappers Reference

| Gum Command | Wrapper Functions |
|-------------|-------------------|
| `style` | `ui_box`, `ui_success`, `ui_error`, `ui_warn`, `ui_text` |
| `confirm` | `ui_confirm` |
| `choose` | `ui_choose`, `ui_choose_multi`, `ui_choose_limit` |
| `input` | `ui_input`, `ui_password`, `ui_input_ext` |
| `write` | `ui_write` |
| `spin` | `ui_spin`, `ui_spin_type`, `ui_spin_output` |
| `table` | `ui_table`, `ui_table_file` |
| `log` | `log_info`, `log_warn`, `log_error`, `log_structured` |

## Testing Framework

Tests use a custom bash framework in `tests/framework.sh`.

```bash
test_file_start "module_name.sh"
source "$PROJECT_DIR/lib/core/module_name.sh"

# Assertions
assert_eq "expected" "$actual" "Check connection status"
assert_success command_to_run
assert_fails invalid_command
assert_function_exists "ui_box"
```
