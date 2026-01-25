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
