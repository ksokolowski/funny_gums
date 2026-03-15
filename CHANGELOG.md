# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
