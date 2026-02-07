# Examples 💡

This document provides detailed walkthroughs of the example scripts in the `examples/` directory.

## Running Examples 🏃‍♂️

All examples can be run directly from the project root:

```bash
./examples/system_dashboard.sh
./examples/csv_viewer.sh [file.csv]
./examples/git_commit.sh
./examples/markdown_preview.sh [file.md]
./examples/openrgb_fix.sh
```

---

## system_dashboard.sh

**An AIDA64/HWiNFO-style system information dashboard.**

### Features
- Sidebar navigation with 8 categories
- Live metrics with configurable refresh interval
- Color-coded temperature and usage indicators
- Auto-refresh toggle
- Terminal size validation

### Categories
1. **Overview** - System summary with key metrics
2. **CPU** - Processor details, temperature, frequency
3. **Memory** - RAM and swap usage with bars
4. **Storage** - Drives, partitions, disk usage
5. **Graphics** - GPU information and temperature
6. **Network** - Interface status, IP addresses, speeds
7. **Audio** - Sound devices (via inxi)
8. **Battery** - Power status (laptops)

### Key Components Used
- `lib/core/term/colors.sh` - Color definitions
- `lib/core/term/cursor.sh` - Cursor positioning for UI
- `lib/ui/layout/ui.sh` - Progress bars, gauges, styled boxes
- `lib/mod/os/system.sh` - All system metrics

### Configuration
```bash
REFRESH_INTERVAL=5      # Seconds between updates
RESOURCE_WARN=70        # Yellow threshold (%)
RESOURCE_CRIT=90        # Red threshold (%)
TEMP_WARN=70            # Temperature warning (°C)
TEMP_CRIT=85            # Temperature critical (°C)
```

### Usage
```bash
# Run dashboard
./examples/system_dashboard.sh

# Keyboard controls:
# ↑/↓ - Navigate categories
# Enter - View details
# A - Toggle auto-refresh
# R - Manual refresh
# Q - Quit
```

---

## csv_viewer.sh

**Interactive CSV/TSV data explorer.**

### Features
- Automatic separator detection (comma, tab, semicolon)
- Interactive table view with gum
- Fuzzy search/filter for rows
- Raw content view with line numbers
- File statistics

### Key Components Used
- `lib/core/term/colors.sh` - Color output
- `lib/ui/layout/ui.sh` - Table, filter, pager, file picker

### Menu Options
1. **View table** - Interactive table display
2. **Filter/search rows** - Fuzzy text search
3. **View raw content** - Line-numbered pager
4. **Show statistics** - Column/row counts, header info

### Usage
```bash
# With file argument
./examples/csv_viewer.sh data.csv

# Interactive file picker
./examples/csv_viewer.sh
```

### Example Session
```
$ ./examples/csv_viewer.sh contacts.csv

╭─ 📄 File: contacts.csv ──────────╮
│                                   │
│ Lines: 150                        │
│ Size: 4.2K                        │
╰───────────────────────────────────╯

Detected separator: comma

What would you like to do?
> 📊 View table
  🔍 Filter/search rows
  📝 View raw content
  📈 Show statistics
  ❌ Exit
```

---

## git_commit.sh

**Interactive conventional commit helper.**

### Features
- Conventional Commits specification support
- Type selection with emoji indicators
- Optional scope, body, and issue references
- Breaking change notation
- Commit message preview before confirmation

### Commit Types
| Type | Emoji | Description |
|------|-------|-------------|
| feat | ✨ | A new feature |
| fix | 🐛 | A bug fix |
| docs | 📚 | Documentation changes |
| style | 💎 | Code style changes |
| refactor | ♻️ | Code refactoring |
| perf | ⚡ | Performance improvement |
| test | 🧪 | Adding/updating tests |
| build | 📦 | Build system changes |
| ci | 🤖 | CI/CD configuration |
| chore | 🔧 | Maintenance |
| revert | ⏪ | Revert a commit |

### Key Components Used
- `lib/core/term/colors.sh` - Color output
- `lib/ui/layout/ui.sh` - Choose, input, write, confirm

### Usage
```bash
# Stage changes first
git add -A

# Run commit helper
./examples/git_commit.sh
```

### Example Session
```
╭─ 🔨 Conventional Commit Helper ──────────╮
│                                           │
│ Create a well-formatted commit message    │
│ following the Conventional Commits spec.  │
╰───────────────────────────────────────────╯

Step 1: Select commit type
Choose commit type:
> feat     ✨ A new feature
  fix      🐛 A bug fix
  docs     📚 Documentation only changes
  ...

Step 2: Enter scope (optional, e.g., api, ui, core)
> auth

Step 3: Enter short description (max 50 chars)
> add password reset functionality

╭─ 📝 Commit Message Preview ──────────╮
│                                       │
│ feat(auth): add password reset        │
│ functionality                         │
╰───────────────────────────────────────╯

Create this commit? [Y/n]
```

---

## markdown_preview.sh

**Markdown file preview with syntax highlighting.**

### Features
- Markdown rendering with gum format
- Code syntax highlighting
- Emoji parsing (:emoji: -> emoji)
- Raw content view with line numbers
- Switch between files

### Key Components Used
- `lib/core/term/colors.sh` - Color output
- `lib/ui/layout/ui.sh` - Format, pager, file picker

### Menu Options
1. **Preview formatted** - Rendered markdown
2. **View as code** - Syntax highlighted source
3. **Preview with emoji parsing** - Emoji conversion
4. **View raw content** - Line-numbered pager
5. **Open different file** - File picker

### Usage
```bash
# With file argument
./examples/markdown_preview.sh README.md

# Interactive file picker
./examples/markdown_preview.sh
```

---

## openrgb_fix.sh

**Multi-step task runner with dashboard UI.**

### Features
- Step-based task execution
- Visual progress tracking
- Spinner animation during execution
- Success/failure status per step
- Sudo credential management
- Logging to file

### Step Categories
| Icon | Category | Purpose |
|------|----------|---------|
| 💾 | disk | Disk operations (hdparm) |
| ⚡ | service | Systemd service control |
| 🌈 | rgb | OpenRGB device control |
| 📦 | package | Package manager updates |

### Key Components Used
- `lib/core/term/colors.sh` - Color definitions
- `lib/core/term/cursor.sh` - Progress UI positioning
- `lib/ui/widgets/spinner.sh` - Animation during tasks
- `lib/core/sh/logging.sh` - Log file output
- `lib/core/sh/sudo.sh` - Credential management
- `lib/ui/layout/ui.sh` - Styled output
- `lib/app/dashboard.sh` - Step tracking UI
- `lib/app/runner.sh` - Command execution

### Usage
```bash
# Requires sudo for disk/service operations
./examples/openrgb_fix.sh
```

### Example Output
```
╭─ OpenRGB Fix ────────────────────────╮
│                                       │
│ 💾 Spin down disk /dev/sda           │
│ ⚡ Stop OpenLinkHub.service          │
│ 🌈 Init OpenRGB device 2 (rainbow)   │
│ ⚡ Start OpenLinkHub.service         │
│ 📦 apt update                        │
│ 📦 apt dist-upgrade                  │
│ 📦 snap refresh                      │
│ 📦 flatpak update                    │
╰───────────────────────────────────────╯

🟢 Step 1/8: Spin down disk /dev/sda
🟢 Step 2/8: Stop OpenLinkHub.service
🔵 Step 3/8: Init OpenRGB device 2...
```

---

## Creating Your Own Examples

Use this template as a starting point:

```bash
#!/usr/bin/env bash
# my_script.sh - Description of what it does
# shellcheck disable=SC1091
set -u

# Resolve script directory (supports symlinks)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Source only what you need
source "$LIB_DIR/core/colors.sh"
source "$LIB_DIR/ui/ui.sh"

# Your script logic here
ui_box "My Script" "Hello, World!"
```
