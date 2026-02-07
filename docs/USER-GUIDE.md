# User Guide

Welcome to the comprehensive User Guide for Funny Gums. This document covers everything from foundational utilities to advanced system monitoring and UI components.

## Table of Contents

- [1. Core Utilities (Foundational)](#1-core-utilities-foundational)
  - [1.1 Terminal & Appearance](#11-terminal--appearance)
  - [1.2 Text & Emojis](#12-text--emojis)
  - [1.3 Shell Utilities](#13-shell-utilities)
- [2. UI Components (Visualization)](#2-ui-components-visualization)
  - [2.1 Layout & Branding](#21-layout--branding)
  - [2.2 Reusable Widgets](#22-reusable-widgets)
  - [2.3 User Interaction](#23-user-interaction)
- [3. System Modules (Monitoring)](#3-system-modules-monitoring)
  - [3.1 Hardware Metrics](#31-hardware-metrics)
  - [3.2 Operating System & BIOS](#32-operating-system--bios)
  - [3.3 Storage & Drives](#33-storage--drives)
  - [3.4 Networking](#34-networking)

---

## 1. Core Utilities (Foundational)

The Core modules provide the essential foundation for any script: terminal handling, text processing, and basic shell utilities.

### 1.1 Terminal & Appearance (`lib/core/term/`)

#### Colors (`colors.sh`) 🎨
ANSI color definitions and helper functions.

```bash
source lib/core/term/colors.sh
```

| Type | Variables | Example Output |
|------|-----------|----------------|
| **Standard** | `$RED`, `$GREEN`, `$YELLOW`, `$BLUE` | `colorize "$RED" "Stop"` |
| **Bright** | `$BRIGHT_RED`, `$BRIGHT_GREEN` | `colorize "$BRIGHT_GREEN" "Go"` |
| **Neon** | `$NEON_PINK`, `$NEON_CYAN`, `$NEON_PURPLE` | `colorize "$NEON_PINK" "Vibrant"` |

#### Cursor Control (`cursor.sh`) 🖱️
Functions for terminal cursor manipulation.

```bash
source lib/core/term/cursor.sh
```

**Common Visual Actions:**
- `cursor_hide` / `cursor_show`: 👁️ Toggle visibility.
- `cursor_save` / `cursor_restore`: 💾 Save/load position.
- `clear_line`: 🧹 Clear the current row.

#### Terminal Detection (`terminal.sh`) 🖥️
Capability detection for the 3-tier emoji system.

```bash
source lib/core/term/terminal.sh
```

**Tier Support:**
- **Tier 1 (Full)**: ⚙️ `full` (Kitty, WezTerm, Ghostty)
- **Tier 2 (Compatible)**: 🔧 `compatible` (GNOME Terminal, VTE)
- **Tier 3 (Legacy)**: `[*]` `legacy` (xterm, TTY)

### 1.2 Text & Emojis (`lib/core/text/`)

#### Visual Width (`text.sh`) 📏
Core logic for calculating display width, handling emojis and CJK characters.

```bash
source lib/core/text/text.sh
```

**Visual Mockup (Padding/Truncation):**
```text
Input: "✅ Done" (Width 15)
Buffer: [✅ Done       ]
```

#### Emoji System (`emojis.sh`, `emoji_registry.sh`) 🎭
Terminal-aware semantic emoji constants.

```bash
source lib/core/text/emojis.sh
```

**Semantic Constants:**
| Logic | Full Tier | Compatible | Legacy |
|-------|-----------|------------|--------|
| **Success** | ✅ | ✅ | `[OK]` |
| **Failure** | ❌ | ❌ | `[FAIL]` |
| **Warning** | ⚠️ | 🟡 | `[!]` |
| **CPU** | ⚙️ | 🔧 | `[*]` |
| **Temp** | 🌡️ | 🔥 | `[T]` |

### 1.3 Shell Utilities (`lib/core/sh/`)

#### Logging (`logging.sh`) 📝
Structured logging with support for log files and verbosity.

```bash
source lib/core/sh/logging.sh
```

**Log Format Exhibit:**
```text
2024-05-20 12:00:00 [INFO]  Started process...
2024-05-20 12:00:01 [DEBUG] Checking dependencies...
2024-05-20 12:00:02 [ERROR] Connection failed: timeout
```

#### Sudo Management (`sudo.sh`) 🛡️
Helpers for authentication and credential keep-alive.

```bash
source lib/core/sh/sudo.sh
```

#### HTTP & API (`http.sh`) 🌐
Optional extension for simple API interactions using `curl`.

---

## 2. UI Components (Visualization)

Funny Gums provides a high-level UI system for building terminal interfaces, powered by [gum](https://github.com/charmbracelet/gum).

### 2.1 Layout & Branding (`lib/ui/layout/`)

#### Base Components (`base.sh`) 📦
Styled boxes and standard messages.

```bash
source lib/ui/layout/base.sh
```

**Visual Mockup (Box):**
```text
╭─────── Title ───────╮
│                     │
│  Content goes here  │
│                     │
╰─────────────────────╯
```

**Semantic Alerts:**
- `ui_success`: 🟢 Success message.
- `ui_error`: 🔴 Error message.
- `ui_warn`: 🟡 Warning message.
- `ui_info`: 🔵 Info message.

#### Formatting (`format.sh`) 📄
Rendering markdown and code snippets using standard terminal styles.

### 2.2 Reusable Widgets (`lib/ui/widgets/`)

#### Gauges & Bars (`gauge.sh`) 📊
Horizontal progress indicators with threshold coloring.

```bash
source lib/ui/widgets/gauge.sh
```

**Component Mockups:**
| Widget | Visual Representation | Key Function |
|--------|-----------------------|--------------|
| **Gauge** | `RAM [████████░░░] 72%` | `ui_gauge` |
| **Status** | `● OK` / `● CRIT` | `ui_status` |
| **V-Bar** | `█` `▆` `▄` `▂` ` ` | `ui_vbar` |

#### Progress & Composition (`progress.sh`) 🏗️
Handling long-running tasks and joining UI elements.

#### Spinners (`spinner.sh`) ⏳
Advanced spinner presets for interactive feedback.

| Presets | Visual Frames |
|---------|---------------|
| **DOTS** | `⠋` `⠙` `⠹` `⠸` `⠼` `⠴` `⠦` `⠧` `⠇` `⠏` |
| **GLOBE** | `🌍` `🌎` `🌏` |
| **MOON** | `🌑` `🌒` `🌓` `🌔` `🌕` `🌖` `🌗` `🌘` |
| **CLOCK** | `🕛` `🕒` `🕕` `🕘` |

#### Tables & Viewers (`table.sh`, `viewer.sh`) 📋
Interactive tables and scrollable text viewers.

### 2.3 User Interaction (`lib/ui/interaction/`)

#### Inputs & Selection (`input.sh`) ⌨️
Gathering information from the user with interactive prompts.

**Interaction Patterns:**
- `ui_confirm`: `Are you sure? [y/N]`
- `ui_choose`: Interactive list selection.
- `ui_input`: Single-line text prompt.

#### Fuzzy Selection (`fzf.sh`) 🔍
Advanced selection using `fzf`. (Optional extension)

---

## 3. System Modules (Monitoring)

System modules provide hardware monitoring and metrics collection. They are organized by domain and rely on various command-line tools.

### 3.1 Hardware Metrics (`lib/mod/hw/`) ⚙️

#### CPU & Thermal (`cpu.sh`, `sensors.sh`) 🌡️
Monitoring processor usage and temperatures.

| Metric | Source Function | Typical Output |
|--------|-----------------|----------------|
| **Usage** | `get_cpu_usage_live` | `15` (%) |
| **Temp** | `get_cpu_temp_live` | `48` (°C) |

#### Graphics (`gpu.sh`, `nvidia.sh`, `amd.sh`) 🎮
GPU metrics for NVIDIA and AMD hardware.

#### Memory (`memory.sh`) 🧠
RAM and Swap statistics.

### 3.2 Operating System & BIOS (`lib/mod/os/`) 🐧

#### System Info (`system.sh`, `dmidecode.sh`) ℹ️
Aggregator module and BIOS/Motherboard queries.

#### Integration (`inxi.sh`, `lspci.sh`) 🔍
Hardware identification and caching wrappers.

### 3.3 Storage & Drives (`lib/mod/storage/`) 💾

#### Metrics & Health (`storage.sh`, `smartctl.sh`) 🏥
Disk usage and drive health.

**Drive Visualization:**
```text
[NVMe] Samsung SSD 980 PRO 1TB
├─ / (ext4)    [██████░░░░] 60%
└─ /home (xfs) [██████████] 100%
```

#### Storage UI (`ui.sh`) 🖼️
Visualization specific to disk layouts (e.g., `ui_drive_layout`).

### 3.4 Networking (`lib/mod/net/`) 📶

#### Metrics & UI (`network.sh`, `ui.sh`) 🌐
Interface status, MAC/IP addresses, and WiFi signal visualization.

**Interface Status Icons:**
- 🟢 `up`: Connected and active.
- 🔴 `down`: Disconnected.
- 🟡 `no-driver`: Hardware detected but no driver loaded.
