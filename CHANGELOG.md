# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Fixes
- Fix awk variable passing and guard against empty/zero denominators to avoid awk syntax errors (lib/mod/os/power.sh)
- Make inxi section matching safe by passing `section` into awk via `-v` (lib/mod/os/inxi.sh)
- Ensure dashboard background jobs inherit mocked functions during tests to restore parallel timing (examples/system_dashboard.sh)


[1.0.0]: https://github.com/ksokolowski/funny_gums/releases/tag/v1.0.0
