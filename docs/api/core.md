# Core Modules API

The core modules provide foundation utilities with no dependencies on other Funny Gums modules.

## colors.sh

ANSI color definitions for terminal output.

```bash
source lib/core/colors.sh
```

### Color Variables

**Basic Colors:**
```bash
$BLACK $RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN $WHITE
```

**Bright Colors:**
```bash
$BRIGHT_BLACK $BRIGHT_RED $BRIGHT_GREEN $BRIGHT_YELLOW
$BRIGHT_BLUE $BRIGHT_MAGENTA $BRIGHT_CYAN $BRIGHT_WHITE
```

**Background Colors:**
```bash
$BG_BLACK $BG_RED $BG_GREEN $BG_YELLOW
$BG_BLUE $BG_MAGENTA $BG_CYAN $BG_WHITE
```

**Text Styles:**
```bash
$BOLD $DIM $ITALIC $UNDERLINE $BLINK $REVERSE $HIDDEN $STRIKETHROUGH
```

**Neon Palette (256-color):**
```bash
$NEON_PINK $NEON_CYAN $NEON_PURPLE $NEON_YELLOW
$NEON_GREEN $NEON_BLUE $NEON_ORANGE $NEON_RED
```

**Reset:**
```bash
$RESET  # Reset all formatting
```

### Functions

#### colorize
Wrap text in color with automatic reset.

```bash
colorize <color> <text...>
```

**Example:**
```bash
colorize "$GREEN" "Success!"
colorize "$BOLD$NEON_CYAN" "Important message"
```

---

## cursor.sh

Cursor control functions for terminal manipulation.

```bash
source lib/core/cursor.sh
```

### Functions

#### cursor_hide / cursor_show
Hide or show the terminal cursor.

```bash
cursor_hide
# Do work with hidden cursor
cursor_show
```

#### cursor_save / cursor_restore
Save and restore cursor position (DEC sequences).

```bash
cursor_save
echo "Temporary output"
cursor_restore
echo "This overwrites the above"
```

#### cursor_up / cursor_down / cursor_left / cursor_right
Move cursor in a direction by N positions.

```bash
cursor_up [n=1]
cursor_down [n=1]
cursor_left [n=1]
cursor_right [n=1]
```

#### cursor_column
Move cursor to column N (1-indexed).

```bash
cursor_column <col>
```

#### cursor_goto
Move cursor to specific row and column (1-indexed).

```bash
cursor_goto <row> <col>
```

#### clear_to_end
Clear from cursor to end of screen.

```bash
clear_to_end
```

#### clear_line_to_end
Clear from cursor to end of current line.

```bash
clear_line_to_end
```

#### clear_line
Clear entire current line.

```bash
clear_line
```

---

## spinner.sh

Spinner animation utilities for progress indication.

```bash
source lib/core/spinner.sh
```

### Predefined Spinner Sets

```bash
SPINNER_FRAMES  # Default: RGB circles
SPINNER_DOTS    # Braille dots
SPINNER_CIRCLE  # Rotating circle quarters
SPINNER_BRAILLE # Braille animation
SPINNER_GLOBE   # Earth rotation
SPINNER_MOON    # Moon phases
SPINNER_CLOCK   # Clock faces
SPINNER_ARROWS  # Rotating arrows
SPINNER_BOUNCE  # Bouncing dot
```

### Functions

#### spinner_set
Set spinner type by name.

```bash
spinner_set <type>
```

**Types:** `DOTS`, `CIRCLE`, `BRAILLE`, `GLOBE`, `MOON`, `CLOCK`, `ARROWS`, `BOUNCE`, `RGB`

**Example:**
```bash
spinner_set DOTS
```

#### spinner_custom
Set custom spinner frames.

```bash
spinner_custom "frame1" "frame2" "frame3" ...
```

**Example:**
```bash
spinner_custom "◜" "◠" "◝" "◞" "◡" "◟"
```

#### spinner_reset
Reset spinner index to 0.

```bash
spinner_reset
```

#### spinner_frame
Get current spinner frame character.

```bash
frame=$(spinner_frame)
```

#### spinner_next
Advance spinner to next frame.

```bash
spinner_next
```

#### spinner_tick
Get current frame and advance (convenience function).

```bash
frame=$(spinner_tick)
```

---

## logging.sh

Structured logging with gum integration.

```bash
source lib/core/logging.sh
```

### Configuration

```bash
LOG_FILE="/tmp/gum_script.log"  # Default log file
VERBOSE=false                    # Enable debug logging
```

### Functions

#### log_init
Initialize log file (clears existing content).

```bash
log_init [file]
```

#### log_info / log_warn / log_error
Log messages at different levels.

```bash
log_info "Starting process"
log_warn "Configuration missing, using defaults"
log_error "Failed to connect"
```

#### log_debug
Log debug messages (only if `VERBOSE=true`).

```bash
VERBOSE=true
log_debug "Variable value: $var"
```

#### log_time
Log with RFC3339 timestamp.

```bash
log_time "Process started"
```

#### log_structured
Structured log with key-value pairs.

```bash
log_structured <level> <message> [key value]...
```

**Example:**
```bash
log_structured info "Processing file" filename "test.txt" size 1024
log_structured error "Request failed" status 500 endpoint "/api/users"
```

#### log_prefix
Log with custom prefix.

```bash
log_prefix "[MyApp]" info "Starting..."
```

#### log_fatal
Log fatal error and exit script.

```bash
log_fatal "Critical error occurred"
# Script exits here
```

#### log_show
Show log file contents in pager.

```bash
log_show
```

---

## sudo.sh

Sudo credential management helpers.

```bash
source lib/core/sudo.sh
```

### Functions

#### sudo_auth
Authenticate sudo and cache credentials.

```bash
if sudo_auth; then
    echo "Sudo authenticated"
fi
```

#### sudo_keepalive_start
Start background process to keep sudo credentials alive.

```bash
sudo_keepalive_start [interval_seconds=50]
```

#### sudo_keepalive_stop
Stop the sudo keepalive background process.

```bash
sudo_keepalive_stop
```

#### sudo_setup
Full sudo setup: authenticate and start keepalive.

```bash
sudo_setup [keepalive_interval=50]
```

#### sudo_cleanup
Cleanup function for script exit.

```bash
trap sudo_cleanup EXIT
```

### Usage Pattern

```bash
#!/usr/bin/env bash
source lib/core/sudo.sh

# Setup sudo with cleanup trap
trap sudo_cleanup EXIT
sudo_setup || exit 1

# Now sudo commands won't prompt for password
sudo some_command
```

---

## terminal.sh

Terminal capability detection with 3-tier classification for emoji support.

```bash
source lib/core/terminal.sh
```

### Terminal Capability Tiers

| Tier | Terminals | VS16 Behavior |
|------|-----------|---------------|
| `full` | Kitty, WezTerm, iTerm, Alacritty, Ghostty, Windows Terminal | Full VS16/ZWJ support |
| `compatible` | VTE-based (GNOME Terminal, Tilix, Terminator) | VS16 stripped, colorful fallbacks |
| `legacy` | Basic xterm, older terminals, TTY | Text-based fallbacks |

### Variables

```bash
$TERMINAL_CAPABILITY  # "full", "compatible", or "legacy"
$TERMINAL_MODE        # "modern" or "legacy" (backward compat)
```

### Functions

#### detect_terminal_capability
Detect and cache the terminal capability tier.

```bash
detect_terminal_capability
echo "Terminal: $TERMINAL_CAPABILITY"
```

#### needs_vs16_stripping
Check if VS16 should be stripped from emojis (for VTE terminals).

```bash
if needs_vs16_stripping; then
    text=$(strip_vs16 "$text")
fi
```

#### supports_zwj
Check if terminal supports ZWJ (Zero Width Joiner) sequences.

```bash
if supports_zwj; then
    echo "👨‍💻"  # ZWJ sequence will render correctly
fi
```

#### is_modern_terminal
Check if terminal displays emojis well (full or compatible tier).

```bash
if is_modern_terminal; then
    echo "Using colorful emojis"
fi
```

### Environment Overrides

```bash
# Force specific capability tier
FUNNY_GUMS_TERMINAL_CAPABILITY=compatible ./script.sh

# Force legacy mode
FUNNY_GUMS_LEGACY_TERMINAL=1 ./script.sh

# Force modern mode
FUNNY_GUMS_MODERN_TERMINAL=1 ./script.sh
```

---

## emoji_registry.sh

Unified emoji registry with automatic terminal-aware fallbacks.

```bash
source lib/core/emoji_registry.sh
```

### The VS16 Problem

VS16 (Variation Selector 16) emojis like ⚠️ and ⚙️ cause alignment issues in VTE terminals:
- **gum** calculates VS16 emoji width as 1
- **VTE** displays VS16 emoji at width 2
- Result: Frame borders become misaligned

The emoji registry solves this by providing semantic fallbacks:

| VS16 Emoji | Compatible Fallback | Legacy Fallback |
|------------|---------------------|-----------------|
| ⚠️ Warning | 🟡 Yellow circle | `[!]` |
| ⚙️ Gear/CPU | 🔧 Wrench | `[*]` |
| 🌡️ Temp | 🔥 Fire | `[T]` |
| 🖥️ Server | 💻 Laptop | `[S]` |
| ⏸️ Pause | 🟠 Orange circle | `\|\|` |
| 🗑️ Trash | ❌ Red X | `[X]` |

### Functions

#### emoji
Get the appropriate emoji for the current terminal capability.

```bash
emoji <NAME>
```

**Example:**
```bash
warning=$(emoji "WARNING")  # Returns ⚠️, 🟡, or [!]
cpu=$(emoji "CPU")          # Returns ⚙️, 🔧, or [*]
```

#### emoji_variant
Get a specific variant regardless of terminal capability.

```bash
emoji_variant <NAME> <full|compatible|legacy>
```

**Example:**
```bash
emoji_variant "WARNING" "full"        # Always returns ⚠️
emoji_variant "WARNING" "compatible"  # Always returns 🟡
emoji_variant "WARNING" "legacy"      # Always returns [!]
```

#### is_registered_emoji
Check if an emoji is in the registry.

```bash
if is_registered_emoji "WARNING"; then
    echo "WARNING is registered"
fi
```

#### strip_vs16
Remove VS16 bytes from text.

```bash
text=$(strip_vs16 "Warning ⚠️")  # Returns "Warning ⚠"
```

### Registered Emojis

**Status:** `WARNING`, `PAUSED`

**Hardware:** `CPU`, `TEMP`, `SERVER`, `PRINTER`

**Actions:** `REMOVE`, `SCISSORS`

**Categories:** `DATABASE`, `CLOUD`, `TAG`

**Nature:** `SUN`, `SNOWFLAKE`

**Hearts:** `HEART_RED`

**Media Controls:** `PLAY_VS`, `STOP_VS`, `RECORD_VS`, `EJECT_VS`, `NEXT_VS`, `PREV_VS`

**Input Devices:** `KEYBOARD_VS`, `MOUSE_VS`, `JOYSTICK_VS`

**Misc:** `UMBRELLA_VS`, `SHIELD_VS`, `SWORDS_VS`, `ALEMBIC_VS`, `RECYCLE_VS`

### Auto-Exported Variables

The registry automatically exports `EMOJI_*` variables based on terminal capability:

```bash
source lib/core/emoji_registry.sh

# These are set automatically:
echo "$EMOJI_WARNING"  # ⚠️, 🟡, or [!]
echo "$EMOJI_CPU"      # ⚙️, 🔧, or [*]
echo "$EMOJI_TEMP"     # 🌡️, 🔥, or [T]
```

---

## emojis.sh

Comprehensive emoji constants organized by category.

```bash
source lib/core/emojis.sh
```

### Categories

**Status Indicators:**
```bash
$EMOJI_SUCCESS  # ✅
$EMOJI_FAILURE  # ❌
$EMOJI_WARNING  # ⚠️ (or fallback)
$EMOJI_OK       # 🟢
$EMOJI_ERROR    # 🔴
$EMOJI_PAUSED   # ⏸️ (or fallback)
$EMOJI_PENDING  # ⬜
$EMOJI_SKIP     # ⏩
$EMOJI_RUNNING  # ⏳
$EMOJI_DONE     # ✨
```

**Colored Circles:**
```bash
$EMOJI_CIRCLE_RED $EMOJI_CIRCLE_ORANGE $EMOJI_CIRCLE_YELLOW
$EMOJI_CIRCLE_GREEN $EMOJI_CIRCLE_BLUE $EMOJI_CIRCLE_PURPLE
$EMOJI_CIRCLE_BLACK $EMOJI_CIRCLE_WHITE
```

**Hardware:**
```bash
$EMOJI_CPU      # ⚙️ (or fallback)
$EMOJI_MEMORY   # 🧠
$EMOJI_DISK     # 💾
$EMOJI_GPU      # 🎮
$EMOJI_POWER    # 🔋
$EMOJI_TEMP     # 🌡️ (or fallback)
$EMOJI_FAN      # 🌀
$EMOJI_RGB      # 🌈
$EMOJI_USB      # 🔌
```

**Actions:**
```bash
$EMOJI_SETUP    # 🔧
$EMOJI_PROCESS  # 🔄
$EMOJI_BUILD    # 🔨
$EMOJI_INSTALL  # 📥
$EMOJI_REMOVE   # 🗑️ (or fallback)
$EMOJI_UPDATE   # 🔃
$EMOJI_SEARCH   # 🔍
```

### Usage in Scripts

```bash
source lib/core/emojis.sh

# Use emoji variables - they auto-adapt to terminal capability
echo "$EMOJI_SUCCESS Setup complete"
echo "$EMOJI_WARNING Check configuration"
echo "$EMOJI_CPU Processing..."
```

---

## text.sh

Visual width calculation and text manipulation for proper terminal alignment.

```bash
source lib/core/text.sh
```

### Functions

#### visual_width
Calculate the visual display width of a string (handles emojis, CJK, ANSI codes).

```bash
width=$(visual_width "Hello 🔧")  # Returns 8 (5 + 1 space + 2 emoji)
```

#### strip_ansi
Remove ANSI escape codes from text.

```bash
plain=$(strip_ansi $'\e[31mRed text\e[0m')  # Returns "Red text"
```

#### pad_visual
Pad string to target visual width.

```bash
pad_visual <text> <width> [alignment]
```

**Alignments:** `left` (default), `right`, `center`

**Example:**
```bash
pad_visual "Hi" 10 left    # "Hi        "
pad_visual "Hi" 10 right   # "        Hi"
pad_visual "Hi" 10 center  # "    Hi    "
```

#### truncate_visual
Truncate string to maximum visual width.

```bash
truncate_visual <text> <max_width> [suffix]
```

**Example:**
```bash
truncate_visual "Hello World" 8 "..."  # "Hello..."
```

#### terminal_safe_text
Apply terminal-specific transformations (strips VS16 for compatible terminals).

```bash
text=$(terminal_safe_text "Warning ⚠️")
# In VTE: "Warning ⚠"
# In Kitty: "Warning ⚠️"
```

#### strip_vs16
Remove VS16 (U+FE0F) bytes from text.

```bash
stripped=$(strip_vs16 "⚠️")  # Returns "⚠"
```

### Gum Width Adjustment

When using gum with emojis, width calculations may differ. These functions help:

#### gum_width_adjustment
Calculate width adjustment needed for gum.

```bash
adj=$(gum_width_adjustment "$text_with_emojis")
```

#### gum_adjusted_width
Get adjusted width for gum frame/box.

```bash
width=$(gum_adjusted_width "$content" 60)
gum style --width "$width" "$content"
```

---

## emoji_data.sh

Low-level emoji width data and detection utilities.

```bash
source lib/core/emoji_data.sh
```

### Constants

```bash
$VS16  # Variation Selector 16 (U+FE0F)
$ZWJ   # Zero Width Joiner (U+200D)
```

### Functions

#### emoji_width
Get the visual width of an emoji.

```bash
emoji_width <emoji> [mode]
```

**Modes:** Uses `$TERMINAL_MODE` by default, or specify `"modern"` / `"legacy"`

**Example:**
```bash
emoji_width "✅"           # Returns 2
emoji_width "⚙️"           # Returns 2 (modern) or 1 (legacy)
emoji_width "⚙️" "legacy"  # Returns 1
```

#### has_vs16
Check if text contains VS16.

```bash
if has_vs16 "⚠️"; then
    echo "Contains VS16"
fi
```

#### has_zwj
Check if text contains ZWJ sequences.

```bash
if has_zwj "👨‍💻"; then
    echo "Contains ZWJ"
fi
```
