# Funny Gums Documentation

Welcome to the Funny Gums documentation. This library provides modular Bash components for building terminal UI applications powered by [gum](https://github.com/charmbracelet/gum).

## Documentation Index

### Getting Started
- **[Getting Started](getting-started.md)** - Installation, dependencies, and your first script

### Architecture
- **[Architecture](architecture.md)** - System design, module relationships, and sourcing patterns

### API Reference
- **[Core Modules](api/core.md)** - Foundation modules (colors, cursor, spinner, logging, sudo)
- **[UI Components](api/ui.md)** - User interface functions (input, display, format, table, gauge)
- **[System Metrics](api/system.md)** - Hardware monitoring functions (CPU, memory, storage, GPU, network)
- **[CLI Tool Abstractions](api/cli-tools.md)** - Wrappers for system utilities (sensors, lspci, smartctl, hdparm, dmidecode, power)

### Examples & Roadmap
- **[Examples](examples.md)** - Detailed walkthroughs of example scripts
- **[Roadmap](roadmap.md)** - Future development plans and planned CLI tool integrations

### Future: The Golden Path
- **[Lessons Learned](future/lessons-learned.md)** - What Funny Gums taught us about bash limitations
- **[Go Charm Project](future/go-charm-project.md)** - Sketch for a proper Go implementation using Charm ecosystem

## Quick Links

### Source Modules
```bash
# Source everything
source funny_gums.sh

# Source only what you need
source lib/core/colors.sh      # Just colors
source lib/ui/ui.sh            # All UI components
source lib/system/system.sh    # All system metrics
source lib/system/cpu.sh       # Just CPU metrics
```

### Run Tests
```bash
./tests/run_tests.sh              # All tests
./tests/run_tests.sh test_cpu.sh  # Specific test
```

### Dependencies
- **Required:** [gum](https://github.com/charmbracelet/gum) - Terminal UI toolkit
- **Optional:** `inxi`, `lm-sensors`, `smartctl`, `hdparm`, `dmidecode`, `acpi`/`upower`

## Module Overview

| Domain | Purpose | Key Functions |
|--------|---------|---------------|
| `lib/core/` | Foundation utilities | Colors, cursor control, spinner, logging |
| `lib/ui/` | Terminal UI components | Input, dialogs, tables, progress bars, gauges |
| `lib/system/` | Hardware metrics | CPU, memory, storage, GPU, network monitoring |
| `lib/dashboard/` | Orchestration | Step-based dashboard UI, command runners |

## License

See the project root for license information.
