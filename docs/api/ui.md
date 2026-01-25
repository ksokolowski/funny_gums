# UI Components API

UI components provide terminal interface functions powered by gum.

```bash
source lib/ui/ui.sh  # All UI components
```

---

## base.sh - Styled Output

### ui_box
Show styled box with rounded border.

```bash
ui_box "Title" "line1" "line2" ...
```

### ui_box_double
Show styled box with double border.

```bash
ui_box_double "Title" "line1" "line2" ...
```

### ui_success
Show success message (green border).

```bash
ui_success "Operation completed!" "Files processed: 42"
```

### ui_error
Show error message (red border).

```bash
ui_error "Failed to connect" "Check network settings"
```

### ui_warn
Show warning message (yellow border).

```bash
ui_warn "Configuration deprecated" "Please update settings"
```

### ui_info
Show info message (cyan, no border).

```bash
ui_info "Processing files..."
```

---

## input.sh - Interactive Input

### ui_confirm
Confirmation dialog (yes/no).

```bash
if ui_confirm "Are you sure?"; then
    echo "Confirmed"
fi

# With default value
ui_confirm "Continue?" --default=false
```

### ui_choose
Single choice selection.

```bash
result=$(ui_choose "Option 1" "Option 2" "Option 3")
```

### ui_choose_multi
Multi-choice selection (no limit).

```bash
results=$(ui_choose_multi "Item 1" "Item 2" "Item 3")
```

### ui_choose_with_header
Choice with descriptive header.

```bash
result=$(ui_choose_with_header "Select an action:" "Build" "Test" "Deploy")
```

### ui_choose_limit
Choice with selection limit.

```bash
result=$(ui_choose_limit 2 "opt1" "opt2" "opt3" "opt4")
```

### ui_choose_selected
Choice with pre-selected items.

```bash
result=$(ui_choose_selected "opt2,opt3" "opt1" "opt2" "opt3" "opt4")
```

### ui_choose_height
Choice with height limit (for long lists).

```bash
result=$(ui_choose_height 5 "opt1" "opt2" ... "opt20")
```

### ui_input
Text input with placeholder.

```bash
result=$(ui_input "Enter your name")
```

### ui_input_header
Input with header and placeholder.

```bash
result=$(ui_input_header "Enter your name:" "John Doe")
```

### ui_input_value
Input with default value.

```bash
result=$(ui_input_value "default text" "Enter value")
```

### ui_input_ext
Advanced input with all gum options.

```bash
ui_input_ext --placeholder "Name" --value "default" --width 40 --header "Enter name:"
```

### ui_password
Password input (masked).

```bash
result=$(ui_password "Enter password")
```

### ui_write
Multi-line text input.

```bash
result=$(ui_write "Enter description")
```

### ui_write_ext
Advanced multi-line input.

```bash
ui_write_ext --header "Description" --width 80 --height 10
```

### ui_filter
Filter/search from piped list.

```bash
result=$(echo -e "item1\nitem2\nitem3" | ui_filter)
```

### ui_filter_header
Filter with header.

```bash
result=$(echo -e "item1\nitem2" | ui_filter_header "Search items:")
```

### ui_file
File picker.

```bash
result=$(ui_file "/path/to/dir")
```

### ui_dir
Directory picker.

```bash
result=$(ui_dir "/path")
```

### ui_file_all
File picker showing hidden files.

```bash
result=$(ui_file_all "/path")
```

---

## format.sh - Text Formatting

### ui_format
Render markdown text.

```bash
echo "# Title" | ui_format
ui_format "# Hello\n- Item 1\n- Item 2"
```

### ui_format_code
Format code with syntax highlighting.

```bash
cat script.sh | ui_format_code
ui_format_code "func main() { }"
```

### ui_format_emoji
Parse emoji codes.

```bash
echo "I :heart: bash" | ui_format_emoji
ui_format_emoji "Hello :wave:"
```

### ui_format_template
Format with Go template syntax.

```bash
echo '{{ Bold "Hello" }}' | ui_format_template
```

---

## table.sh - Tables and Pagers

### ui_table
Display interactive table from CSV/TSV.

```bash
cat data.csv | ui_table
ui_table --separator "," --columns "Name,Age,City" < data.csv
ui_table --border rounded --file data.csv
```

### ui_table_file
Display table from file.

```bash
ui_table_file data.csv
ui_table_file data.csv --separator ","
```

### ui_table_columns
Display table with custom columns.

```bash
ui_table_columns "Name,Age" < data.csv
```

### ui_pager
Scrollable text viewer.

```bash
cat README.md | ui_pager
```

### ui_pager_numbered
Pager with line numbers.

```bash
cat script.sh | ui_pager_numbered
```

### ui_pager_wrap
Pager with soft wrap.

```bash
cat longlines.txt | ui_pager_wrap
```

---

## progress.sh - Spinners and Layout

### ui_spin
Show spinner while command runs.

```bash
ui_spin "Loading..." command args...
ui_spin "Loading..." --spinner dot -- command args...
```

### ui_spin_type
Spinner with specific type.

```bash
ui_spin_type dot "Loading..." command args...
```

**Types:** `line`, `dot`, `minidot`, `jump`, `pulse`, `points`, `globe`, `moon`, `monkey`, `meter`, `hamburger`

### ui_spin_output
Spinner showing command output.

```bash
ui_spin_output "Building..." make build
```

### ui_join_h
Join text horizontally.

```bash
result=$(ui_join_h "text1" "text2")
```

### ui_join_v
Join text vertically.

```bash
result=$(ui_join_v "text1" "text2")
```

---

## gauge.sh - Progress Bars

### ui_gauge
Basic horizontal progress bar.

```bash
ui_gauge <current> <max> [width=20] [label]
```

**Example:**
```bash
ui_gauge 62 100 20 "RAM"
# Output: RAM      [████████████░░░░░░░░] 62%
```

### ui_gauge_colored
Color-coded progress bar with thresholds.

```bash
ui_gauge_colored <current> <max> [width=20] [label] [warn=70] [crit=90]
```

Colors: green (< warn), yellow (warn-crit), red (>= crit)

### ui_temp_gauge
Temperature display with status coloring.

```bash
ui_temp_gauge <temp_celsius> [warn=70] [crit=85] [label="Temp"]
```

### ui_vbar
Single-character vertical bar (Unicode blocks).

```bash
char=$(ui_vbar 75)
# Output: ▆
```

### ui_status
Colored status indicator dot.

```bash
ui_status "OK"      # Green dot
ui_status "WARN"    # Yellow dot
ui_status "CRIT"    # Red dot
ui_status "UNKNOWN" # Gray dot
```

### ui_minibar
Compact horizontal bar (no label).

```bash
ui_minibar <percent> [width=5]
```

### ui_minibar_colored
Colored mini bar with thresholds.

```bash
ui_minibar_colored <percent> [width=5] [warn=70] [crit=90]
```

---

## storage.sh - Storage Visualization

### ui_partition_bar
Build partition layout bar.

```bash
ui_partition_bar <total_size> <width> "size1|color1" "size2|color2" ...
```

**Example:**
```bash
ui_partition_bar 1000000000 40 "500000000|$NEON_GREEN" "500000000|$NEON_BLUE"
```

### ui_drive_layout
Drive visualization with partition layout.

```bash
ui_drive_layout "model" "size_hr" "type" <total_bytes> <bar_width> "partitions..."
```

**Partition format:** `"name|size_bytes|fstype|mountpoint|used_bytes"`

**Drive types:** `nvme`, `ssd`, `hdd`

### ui_fs_legend
Generate filesystem color legend.

```bash
ui_fs_legend
# Output: █ext4 █ntfs █fat █btrfs █xfs █swap ░free
```

---

## network.sh - Network Visualization

### ui_net_status
Network status with colored indicator.

```bash
ui_net_status "up"        # ● Connected (green)
ui_net_status "down"      # ○ Disconnected (red)
ui_net_status "no-driver" # ◌ No Driver (yellow)
```

### ui_net_type_icon
Network interface type icon.

```bash
ui_net_type_icon "ethernet"  # 🔌
ui_net_type_icon "wireless"  # 📶
```

### ui_net_interface_line
Compact network interface display.

```bash
ui_net_interface_line "eth0" "ethernet" "up" "1000 Mbps" "192.168.1.100" "Intel I226"
```

### ui_wifi_signal
WiFi signal strength bar.

```bash
ui_wifi_signal 75 5
# Output: ████░ 75%
```
