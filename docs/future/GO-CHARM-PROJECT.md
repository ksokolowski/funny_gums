# Go Charm Project - The Golden Path

> Lessons learned from Funny Gums, applied properly in Go.

## Overview

Funny Gums demonstrated that bash can be pushed far with good architecture, but also revealed fundamental limitations. This document sketches a proper Go implementation using the Charm ecosystem.

## Why Go + Charm?

### Problems Solved (lessons from Funny Gums)

| Bash Pain Point | Go Solution |
|-----------------|-------------|
| Manual UTF-8 byte manipulation for VS16 emojis | Native Unicode support, `runewidth` package |
| Environment variable hacking for terminal detection | `termenv` package, proper terminfo |
| Global variables for state | Structured data, Bubble Tea model |
| String-based assertions in tests | Type-safe testing, `testify` |
| Sourcing order dependencies | Go imports, compile-time checks |
| No parallelism (subshells are slow) | Goroutines, channels |
| Shell escaping nightmares | Proper string handling |

### Charm Ecosystem

```
┌─────────────────────────────────────────────────────┐
│                   Your Application                   │
├─────────────────────────────────────────────────────┤
│  Bubble Tea          │  Lip Gloss      │  Bubbles   │
│  (TUI Framework)     │  (Styling)      │  (Components)
├─────────────────────────────────────────────────────┤
│  termenv (terminal)  │  runewidth (unicode)         │
└─────────────────────────────────────────────────────┘
```

- **Bubble Tea**: Elm-inspired reactive TUI framework
- **Lip Gloss**: CSS-like terminal styling
- **Bubbles**: Pre-built components (spinners, text inputs, lists, tables)
- **Harmonica**: Animations and transitions

## Architecture Sketch

### Project Structure

```
charm-dashboard/
├── cmd/
│   └── dashboard/
│       └── main.go           # Entry point
├── internal/
│   ├── model/
│   │   ├── app.go            # Main application model
│   │   ├── dashboard.go      # Dashboard state
│   │   └── metrics.go        # System metrics state
│   ├── view/
│   │   ├── layout.go         # Grid/pane layouts
│   │   ├── widgets.go        # Reusable UI widgets
│   │   └── styles.go         # Lip Gloss styles
│   ├── system/
│   │   ├── cpu.go            # CPU metrics
│   │   ├── memory.go         # Memory metrics
│   │   ├── storage.go        # Disk metrics
│   │   ├── gpu.go            # GPU metrics (nvidia-smi, amdgpu)
│   │   └── network.go        # Network metrics
│   └── update/
│       ├── commands.go       # Bubble Tea commands
│       └── messages.go       # Custom message types
├── pkg/
│   └── gauge/
│       ├── bar.go            # Progress bar component
│       ├── minibar.go        # Compact bar
│       └── threshold.go      # Color thresholds
├── go.mod
└── go.sum
```

### Bubble Tea Model Pattern

```go
package model

import (
    tea "github.com/charmbracelet/bubbletea"
    "github.com/charmbracelet/lipgloss"
)

// App is the main application model
type App struct {
    // State
    metrics    Metrics
    dashboard  Dashboard

    // UI State
    width      int
    height     int
    focused    int

    // Components (from Bubbles)
    spinner    spinner.Model
    table      table.Model
}

// Init implements tea.Model
func (a App) Init() tea.Cmd {
    return tea.Batch(
        a.spinner.Tick,
        fetchMetrics(),
    )
}

// Update implements tea.Model
func (a App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        switch msg.String() {
        case "q", "ctrl+c":
            return a, tea.Quit
        case "tab":
            a.focused = (a.focused + 1) % panelCount
        }
    case tea.WindowSizeMsg:
        a.width = msg.Width
        a.height = msg.Height
    case MetricsMsg:
        a.metrics = msg.Metrics
        return a, fetchMetricsAfter(time.Second)
    }
    return a, nil
}

// View implements tea.Model
func (a App) View() string {
    return lipgloss.JoinVertical(
        lipgloss.Left,
        a.renderHeader(),
        lipgloss.JoinHorizontal(
            lipgloss.Top,
            a.renderCPUPanel(),
            a.renderMemoryPanel(),
        ),
        a.renderFooter(),
    )
}
```

### Reusable Gauge Component

```go
package gauge

import (
    "github.com/charmbracelet/lipgloss"
    "github.com/mattn/go-runewidth"
)

type Bar struct {
    Width      int
    Percent    float64
    ShowLabel  bool
    Thresholds []Threshold
}

type Threshold struct {
    Value float64
    Style lipgloss.Style
}

func (b Bar) View() string {
    filled := int(float64(b.Width) * b.Percent)
    empty := b.Width - filled

    style := b.styleForValue(b.Percent)

    bar := style.Render(strings.Repeat("█", filled)) +
           strings.Repeat("░", empty)

    if b.ShowLabel {
        label := fmt.Sprintf(" %3.0f%%", b.Percent*100)
        bar += label
    }

    return bar
}

func (b Bar) styleForValue(v float64) lipgloss.Style {
    for i := len(b.Thresholds) - 1; i >= 0; i-- {
        if v >= b.Thresholds[i].Value {
            return b.Thresholds[i].Style
        }
    }
    return lipgloss.NewStyle()
}
```

### System Metrics Collection

```go
package system

import (
    "bufio"
    "os"
    "strconv"
    "strings"
)

type CPUMetrics struct {
    UsagePercent float64
    Temperature  float64
    Frequency    float64
    LoadAvg      [3]float64
    CoreCount    int
}

func GetCPUMetrics() (CPUMetrics, error) {
    var m CPUMetrics

    // /proc/stat for usage
    // /sys/class/thermal for temp
    // /proc/cpuinfo for freq
    // /proc/loadavg for load

    return m, nil
}

// Command for Bubble Tea async fetching
func FetchCPU() tea.Cmd {
    return func() tea.Msg {
        metrics, err := GetCPUMetrics()
        if err != nil {
            return CPUErrorMsg{err}
        }
        return CPUMetricsMsg{metrics}
    }
}
```

## Key Design Decisions

### 1. Reactive Model (Bubble Tea)

Unlike Funny Gums' imperative "draw-update-draw" loop:
- State changes trigger automatic re-renders
- Messages drive updates (keyboard, timers, async results)
- No manual cursor manipulation

### 2. Component Composition

```go
// Compose views with Lip Gloss
func (a App) renderDashboard() string {
    left := lipgloss.JoinVertical(lipgloss.Left,
        a.cpuWidget.View(),
        a.memWidget.View(),
    )
    right := lipgloss.JoinVertical(lipgloss.Left,
        a.diskWidget.View(),
        a.netWidget.View(),
    )
    return lipgloss.JoinHorizontal(lipgloss.Top, left, right)
}
```

### 3. Styling with Lip Gloss

```go
var (
    titleStyle = lipgloss.NewStyle().
        Bold(true).
        Foreground(lipgloss.Color("205")).
        MarginBottom(1)

    panelStyle = lipgloss.NewStyle().
        Border(lipgloss.RoundedBorder()).
        BorderForeground(lipgloss.Color("62")).
        Padding(1, 2)

    errorStyle = lipgloss.NewStyle().
        Foreground(lipgloss.Color("196"))
)
```

### 4. Async Data Fetching

```go
// Bubble Tea commands for non-blocking I/O
func fetchMetrics() tea.Cmd {
    return tea.Batch(
        FetchCPU(),
        FetchMemory(),
        FetchDisk(),
        FetchNetwork(),
    )
}

// Periodic refresh
func fetchMetricsAfter(d time.Duration) tea.Cmd {
    return tea.Tick(d, func(t time.Time) tea.Msg {
        return RefreshMsg{}
    })
}
```

## Migration Path from Funny Gums

### Phase 1: Core Components
- [ ] Gauge/progress bar with thresholds
- [ ] Table component with sorting
- [ ] Box/panel layouts

### Phase 2: System Metrics
- [ ] CPU (usage, temp, freq, load)
- [ ] Memory (used, available, swap)
- [ ] Storage (partitions, usage, I/O)
- [ ] GPU (NVIDIA, AMD)
- [ ] Network (interfaces, traffic)

### Phase 3: Dashboard
- [ ] Multi-pane layout
- [ ] Keyboard navigation
- [ ] Configuration file support
- [ ] Theme support

### Phase 4: Polish
- [ ] Animations (harmonica)
- [ ] Mouse support
- [ ] Responsive layouts
- [ ] Plugin system?

## Potential Project Names

- `charm-dash` - Dashboard using Charm
- `sysview` - System viewer
- `termstat` - Terminal statistics
- `glance` - Quick system glance (like btop/htop)
- `pulse` - System pulse monitor

## Dependencies

```go
require (
    github.com/charmbracelet/bubbletea v0.25+
    github.com/charmbracelet/bubbles v0.17+
    github.com/charmbracelet/lipgloss v0.9+
    github.com/charmbracelet/harmonica v0.2+
    github.com/mattn/go-runewidth v0.0.15+
    github.com/shirou/gopsutil/v3 v3.23+  // Cross-platform system metrics
)
```

## References

- [Bubble Tea Tutorial](https://github.com/charmbracelet/bubbletea/tree/master/tutorials)
- [Bubbles Components](https://github.com/charmbracelet/bubbles)
- [Lip Gloss Docs](https://github.com/charmbracelet/lipgloss)
- [gopsutil](https://github.com/shirou/gopsutil) - Cross-platform system metrics
- [Awesome Charm](https://github.com/charmbracelet/charm#charm-projects) - Example projects

## Notes

This document captures the "golden path" - what we'd do if starting fresh with proper tools. Funny Gums remains valuable as:
- Learning exercise in bash architecture
- Prototype for testing UI ideas quickly
- Reference for what NOT to do in production
