# Lessons Learned from Funny Gums

> What building a "proper" bash library taught us about bash limitations.

## The Good

### Bash CAN be structured
- Module guard patterns work well
- Function prefixing creates pseudo-namespaces
- Associative arrays enable O(1) lookups
- Sourcing order can be managed with loader scripts

### Gum is excellent
- Wrapping gum CLI is straightforward
- Output is consistent and beautiful
- Spinners, inputs, tables work reliably

### Tests are possible
- Custom assertion framework works
- 380+ tests provide confidence
- Shellcheck catches many issues early

## The Bad

### Unicode is painful
```bash
# What we had to do for VS16 emoji support:
VS16=$(printf '\xef\xb8\x8f')  # Manual UTF-8 bytes
GEAR_VS16=$(printf '\xe2\x9a\x99')${VS16}  # Hand-craft each emoji

# What Go does:
width := runewidth.StringWidth("⚙️")  // Just works
```

### Terminal detection is hacky
```bash
# Bash: environment variable archaeology
is_modern_terminal() {
    case "${TERM_PROGRAM:-}" in
        WezTerm|iTerm*|kitty|...) return 0 ;;
    esac
    return 1
}

# Go: termenv handles it
profile := termenv.ColorProfile()
```

### State management is global soup
```bash
# Bash: globals everywhere
DASHBOARD_STEPS=()
SPINNER_IDX=0
RUNNER_CMD_PID=""

# Go: structured state
type App struct {
    Steps   []Step
    Spinner spinner.Model
    Cmd     *exec.Cmd
}
```

### No real parallelism
```bash
# Bash: subshells are slow, no shared state
result=$(long_running_command)  # Blocks everything

# Go: goroutines are cheap
go func() {
    result <- longRunningCommand()
}()
```

## The Ugly

### Git + Unicode = Chaos
- VS16 characters in source files got corrupted
- Had to encode ALL emojis as hex bytes
- CI vs local environment differences

### Error handling is afterthought
```bash
# Bash: hope nothing fails
result=$(some_command)
[[ -n "$result" ]] || result="fallback"

# Go: explicit error handling
result, err := someFunction()
if err != nil {
    return fmt.Errorf("context: %w", err)
}
```

### Testing edge cases is tedious
```bash
# Bash: string comparison only
assert_eq "2" "$(visual_width "⚙️")" "Gear width"

# Go: rich assertions, table-driven tests
tests := []struct{
    input string
    want  int
}{
    {"⚙️", 2},
    {"Hello", 5},
}
for _, tt := range tests {
    got := visualWidth(tt.input)
    assert.Equal(t, tt.want, got)
}
```

## Specific Technical Lessons

### 1. Emoji Width Calculation

**Problem**: Different terminals render emojis at different widths.

**Bash solution**:
- Pre-computed lookup tables
- Hex-encoded keys to avoid git corruption
- Terminal mode detection (modern vs legacy)
- ~200 lines of code

**Go solution**:
```go
import "github.com/mattn/go-runewidth"
width := runewidth.StringWidth(text)
```

### 2. Progress Bars with Thresholds

**Problem**: Color changes based on value (green → yellow → red).

**Bash solution**:
```bash
_ui_threshold_color() {
    local value=$1
    if (( value >= 90 )); then echo "$RED"
    elif (( value >= 70 )); then echo "$YELLOW"
    else echo "$GREEN"; fi
}
```

**Go solution**:
```go
type Threshold struct {
    Value float64
    Style lipgloss.Style
}
// Then use with any numeric type, not just integers
```

### 3. Async Updates

**Problem**: Dashboard needs periodic metric updates without blocking input.

**Bash solution**:
- Background processes
- Temp files for IPC
- Signal handlers
- Complex cleanup

**Go solution**:
```go
func tick() tea.Cmd {
    return tea.Tick(time.Second, func(t time.Time) tea.Msg {
        return TickMsg(t)
    })
}
```

### 4. Layout Management

**Problem**: Multi-pane dashboard with dynamic sizing.

**Bash solution**:
- Manual ANSI cursor positioning
- Calculate positions based on terminal size
- Redraw entire screen on changes
- Flicker issues

**Go solution**:
```go
lipgloss.JoinHorizontal(lipgloss.Top,
    leftPanel.Width(width/2).Render(left),
    rightPanel.Width(width/2).Render(right),
)
```

## What to Carry Forward

### Keep
- Modular architecture
- Clear naming conventions
- Comprehensive testing
- Documentation-first approach

### Improve
- Use proper language for the job
- Leverage existing libraries (don't reinvent wheels)
- Type safety over string manipulation
- Structured error handling

### Abandon
- Manual Unicode byte handling
- Global state management
- Environment variable archaeology
- Bash for complex TUI applications

## Conclusion

Funny Gums proved that bash can be pushed surprisingly far with good architecture. But it also clearly showed where bash's limits are. The Go + Charm stack eliminates almost every pain point we encountered.

**Funny Gums value**:
- Rapid prototyping
- Learning bash internals
- Discovering what a "proper" solution needs

**Go + Charm value**:
- Production-ready TUI applications
- Maintainable codebase
- Cross-platform support
- Actual fun to work with
