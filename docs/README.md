# Documentation Hub 📖

Welcome to the Funny Gums documentation. This library provides modular Bash components for building terminal UI applications.

## Documentation Index 🗂️

### 🏁 Getting Started
- **[Getting Started](GETTING-STARTED.md)** - Installation, dependencies, and your first script.

### 🏛️ System Design
- **[Architecture](ARCHITECTURE.md)** - System design, module relationships, and sourcing patterns.
- **[User Guide](USER-GUIDE.md)** - Comprehensive API reference for all modules.

### 💡 Resources
- **[Examples](EXAMPLES.md)** - Detailed walkthroughs of example scripts.
- **[Roadmap](ROADMAP.md)** - Future development plans and planned integrations.

### 🔮 Future: The Golden Path
- **[Lessons Learned](future/LESSONS-LEARNED.md)** - What Funny Gums taught us about bash limitations.
- **[Go Charm Project](future/GO-CHARM-PROJECT.md)** - Sketch for a proper Go implementation.

## Quick Links

### Source Modules
```bash
# Source everything
source funny_gums.sh

# Source specifically
source lib/core/term/colors.sh      # Just colors
source lib/ui/layout/ui.sh          # All UI components
source lib/mod/os/system.sh         # All system metrics
source lib/mod/hw/cpu.sh            # Just CPU metrics
```

### Run Tests
```bash
./tests/run_tests.sh               # All tests
./tests/run_tests.sh test_text.sh  # Specific test
```

### Dependencies
- **Required:** [gum](https://github.com/charmbracelet/gum) - Terminal UI toolkit
- **Optional:** `inxi`, `lm-sensors`, `smartctl`, `hdparm`, `dmidecode`, `acpi`/`upower`

## Module Overview

| Tier | Location | Purpose |
|------|----------|---------|
| **Core** | `lib/core/` | Foundation: Term, Text, Sh utilities |
| **UI** | `lib/ui/` | Visualization: Layout, Widgets, Interaction |
| **Modules** | `lib/mod/` | Domain: HW, OS, Storage, Net monitoring |
| **App** | `lib/app/` | Orchestration: Dashboard, Runner logic |

## License

See the project root for license information.
