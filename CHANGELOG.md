# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-05-17

### Added
- **logging.sh**: `LOGGING_QUIET` contract. When set to `true`, all `log_*` functions write to `LOG_FILE` only — no `tee` to stdout. Lets TUI components own the terminal without log lines desynchronising cursor accounting. `dashboard_init` toggles it automatically; new `dashboard_cleanup` restores prior state and is recommended in the EXIT trap alongside `cursor_show` / `runner_cleanup`.
- **tests/test_strict_mode.sh**: Smoke test that loads the full library under `set -uo pipefail` and exercises a representative slice of the public API (every `NEON_*_NUM` and `EMOJI_*` the bundled examples touch, plus dashboard state machine and pure helpers). Catches the class of unbound-variable regression that `NEON_RED_NUM` slipped through.
- **tests/test_deps.sh**: First unit tests for `deps.sh`, including the standalone-bootstrap path.
- **colors.sh**: `ANSI_<COLOR>_NUM` constants (BLACK..WHITE = 0..7) mirroring the existing `NEON_*_NUM` pattern. `ui/layout/base.sh` now uses the named constants instead of bare numeric literals.
- **dashboard.sh**: `DASHBOARD_TITLE_ICON` global + optional second argument to `dashboard_init` for replacing or suppressing the hardcoded 🔧 prefix. Default behaviour unchanged.
- **dashboard.sh**: `DASHBOARD_PADDING_TOP` / `DASHBOARD_PADDING_LEFT` plus internal `_dashboard_steps_start` / `_dashboard_spinner_col` helpers. The frame padding fed to gum, the first-step row offset, and the spinner glyph column are now derived from one set of inputs; bumping the padding can no longer silently move the spinner off-glyph.
- **sudo.sh**: `sudo_auth_styled [width]` / `sudo_setup_styled [keepalive] [width]` now accept width as an explicit argument. `SUDO_FRAME_WIDTH` is kept as a back-compat fallback.

### Fixed
- **colors.sh**: Added missing `NEON_RED_NUM`, `NEON_YELLOW_NUM`, `NEON_BLUE_NUM`, `NEON_ORANGE_NUM` 256-color index siblings. `examples/openrgb_fix.sh` aborted under `set -u` on the failure path because `NEON_RED_NUM` was undefined.
- **runner.sh + dashboard.sh**: The `tee`-to-stdout in `log_error` advanced the cursor below the dashboard between steps, desynchronising `dashboard_draw`'s `cursor_up`/`clear_to_end` arithmetic and leaving an orphan `╭──╮` top border on the next redraw whenever a step failed. Now solved generally via the `LOGGING_QUIET` contract (see Added).
- **deps.sh**: Standalone-bootstrap branch checked `$_DEPS_DIR/colors.sh` for existence, but `colors.sh` lives in `../term/`. The conditional `source` therefore never ran when `deps.sh` was loaded on its own. Path fixed.
- **tests/test_text.sh**: Removed three misplaced `strip_vs16` assertions from the `emoji_registry.sh` test section — `strip_vs16` is defined in `text.sh`, so the assertions only passed inside `make check` (where earlier test files happened to source `text.sh` first) and failed in isolation. Already-covered by the `text.sh` section.
- **funny_gums.sh** + **CLAUDE.md**: The loader sourced `lib/ui/widgets/spinner.sh` under the "Core modules (no dependencies)" block but the architecture doc claimed spinner is at Level 1. Reconciled: spinner is a leaf widget loaded early so the dashboard can depend on it.

### Changed
- **text.sh**: `strip_ansi`, `strlen_no_ansi`, `strlen_no_ansi_ref` consolidated onto a single `_ansi_strip_to_var` state machine. Previously each function inlined its own ESC-CSI scanner; diverging fixes was a matter of when. `strip_ansi` now also takes the no-ESC fast-path that the two `strlen` variants already had.
- **runner.sh**: `runner_exec_all` comment no longer claims the `bash -c "$cmd"` form is "safely without eval" — it isn't. Documented the real safety property (only safe with script-author literal commands, never with user input).
- **gum_wrapper.sh**: Removed duplicated doc-comment block above `gum_exec_style_visual`.
- **sudo.sh**: Removed dead `width_arg` local variable that was assigned but never read.
- **examples/**: All eight bundled examples now use a unified two-line `readlink -f` bootstrap instead of the verbose 7-line manual symlink-walking preamble (or the 2-line non-symlink-safe variant). `LIB_DIR` is no longer defined in scripts that don't actually use it.
- **examples/system_dashboard.sh**: CLR_* palette moved below the `source` so it can alias the lib's NEON_* constants for the slots that match (CLR_HIGHLIGHT, CLR_CRIT, CLR_POWER); local block stays because it's appropriately richer than the lib's 8-shade accent palette. Documented as the recommended pattern for layering a script-local theme on top of the library.

### Fixed
- **colors.sh**: Added missing `NEON_RED_NUM`, `NEON_YELLOW_NUM`, `NEON_BLUE_NUM`, `NEON_ORANGE_NUM` 256-color index siblings. `examples/openrgb_fix.sh` aborted under `set -u` on the failure path because `NEON_RED_NUM` was undefined.
- **runner.sh + dashboard.sh**: The `tee`-to-stdout in `log_error` advanced the cursor below the dashboard between steps, desynchronising `dashboard_draw`'s `cursor_up`/`clear_to_end` arithmetic and leaving an orphan `╭──╮` top border on the next redraw whenever a step failed. Now solved generally via the `LOGGING_QUIET` contract (see Added).
- **deps.sh**: Standalone-bootstrap branch checked `$_DEPS_DIR/colors.sh` for existence, but `colors.sh` lives in `../term/`. The conditional `source` therefore never ran when `deps.sh` was loaded on its own. Path fixed.

### Changed
- **text.sh**: `strip_ansi`, `strlen_no_ansi`, `strlen_no_ansi_ref` consolidated onto a single `_ansi_strip_to_var` state machine. Previously each function inlined its own ESC-CSI scanner; diverging fixes was a matter of when. `strip_ansi` now also takes the no-ESC fast-path that the two `strlen` variants already had.

## [1.1.0] - 2026-03-15

### Fixed
- **gum_wrapper.sh**: `exit 1` at source time killed host scripts when gum was missing — changed to `return 1`
- **logging.sh**: Bare `$VERBOSE` command execution replaced with safe `[[ "$VERBOSE" == "true" ]]` check
- **dashboard.sh**: All bare-command boolean patterns (`$DASHBOARD_QUIET`, `$enabled`, etc.) replaced with safe comparisons
- **terminal.sh**: `_is_full_terminal` required both TERM and TERM_PROGRAM to match — split into independent checks
- **spinner.sh**: `((SPINNER_IDX++))` returned exit code 1 under `set -e` when index was 0
- **base.sh (ui)**: `ui_info` was missing `--no-strip-ansi` flag unlike sibling functions
- **text.sh**: `truncate_visual` lost ANSI formatting when text already fit within limit
- **system_dashboard.sh**: Wrong variable names for battery metrics (`POWER_BATTERY_*` → `LIVE_BATTERY_*`), missing VRAM raw values for GPU percentage calculation
- **power.sh**: Fractional minutes calculation broken by locale comma separator (`3,5` vs `3.5`)
- **sensors.sh**: Added `LC_ALL=C` to all `sensors` calls for locale-safe parsing; awk-based adapter matching replaces fragile sed regex
- **Makefile**: `shellcheck lib/**/*.sh` glob didn't recurse — replaced with `find | xargs`

### Improved
- **http.sh**: Eliminated command injection via `bash -c "$cmd"` — calls curl directly; added `trap` for temp file cleanup
- **runner.sh**: Added INT/TERM signal traps around background jobs for proper cleanup
- **sudo.sh**: Keepalive loop now exits when credentials expire instead of looping forever
- **sensors.sh**: `sensors_get_fan_speeds` outputs structured `name|rpm` pairs via awk instead of bare numbers
- **base.sh (mod)**: Input validation in `format_bytes` and `format_kb` for non-numeric/empty values
- **inxi.sh**: Added `command -v inxi` guard before cache attempt
- **storage.sh**: Added `command -v jq` guard before JSON parsing
- **input.sh**: `shift || true` for optional args in 5 interaction functions
- **lspci.sh**: `grep -E "$filter"` → `grep -F "$filter"` to prevent regex injection
- **deps.sh**: `dep_require_all` uses `return 1` instead of `exit 1`
- **emoji_registry.sh**: Removed duplicate `strip_vs16` (already defined in text.sh)
- **ui.sh**: Added missing module sources for spinner, viewer, and fzf
- **progress.sh**: Simplified `ui_join_h`/`ui_join_v` from N-1 subshell loop to single gum call

### Tests
- **framework.sh**: Clarified `assert_contains` parameter naming (`expected` → `substring`)
- **test_dashboard_parallel.sh**: Mocked sequential functions to isolate parallel timing; fixed mock leakage via re-sourcing modules after cleanup
- **test_dmidecode.sh**: Replaced `exit 1` with proper assertions; added mock cleanup
- **test_hdparm.sh**, **test_amd.sh**, **test_nvidia.sh**: Replaced manual echo checks with `assert_*` framework calls
- **test_sensors_parsing.sh**: Registered sub-checks in test counters
- **test_enhancements.sh**, **test_inxi_helper.sh**: Removed premature `print_summary` calls that caused mid-suite partial summaries

### Developer Experience
- **scripts/pre-commit**: Silent on success, shows full output on failure
- **Makefile**: `make clean` now removes test log temp files
- **.editorconfig**: Added to codify formatting conventions (4-space indent for `.sh`, tabs for Makefile, LF, UTF-8)

## [1.0.0] - 2026-02-09

### Added
- Initial public release
- **Core modules**: Colors, cursor control, terminal detection, logging, sudo management
- **UI components**: Boxes, inputs, tables, progress bars, spinners, pagers
- **System monitoring**: CPU, GPU, memory, storage, network, sensors
- **Dashboard system**: Multi-step progress tracking with live updates
- **Emoji system**: 3-tier capability detection (full/compatible/legacy) with VS16 support
- **Extension modules**: HTTP client (curl+jq), FZF integration, smart file viewer (bat/glow)
- **Examples**: 9 working examples including system_dashboard, openrgb_fix, git_commit, api_browser
- **Testing**: 300+ automated tests with shellcheck integration
- **CI/CD**: GitHub Actions workflow for automated testing
- **Documentation**: Comprehensive docs (Getting Started, Architecture, User Guide, API Reference)
- **Funding**: GitHub Sponsors and Ko-fi support

### Features
- Modular architecture with hierarchical dependency loading
- Terminal capability detection (Kitty, WezTerm, iTerm, VS Code, GNOME Terminal)
- Visual width calculation for emoji-aware text processing
- Structured logging with gum integration
- Sudo credential management with keepalive
- Hardware monitoring wrappers (inxi, nvidia-smi, smartctl, sensors)
- Color-coded thresholds for system metrics
- Auto-refresh dashboard with keyboard navigation

[1.1.0]: https://github.com/ksokolowski/funny_gums/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ksokolowski/funny_gums/releases/tag/v1.0.0
