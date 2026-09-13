#!/usr/bin/env bash
# test_nvidia_dashboard.sh - Unit tests for the NVIDIA + 12VHPWR dashboard

test_file_start "nvidia_dashboard.sh"

# Copy dashboard to temp file, removing init/loop invocation
TMP_DASHBOARD=$(mktemp)
head -n -2 "$PROJECT_DIR/examples/nvidia_dashboard.sh" >"$TMP_DASHBOARD"

# Resolve the bootstrap against the real example path
sed -i 's|_SELF="$(readlink -f "${BASH_SOURCE\[0\]}" 2>/dev/null .*)"|_SELF="'"$PROJECT_DIR/examples/nvidia_dashboard.sh"'"|' "$TMP_DASHBOARD"

# shellcheck source=/dev/null
source "$TMP_DASHBOARD"

TERM_COLS=100
TERM_ROWS=30
GPU_PANEL_WIDTH=$((TERM_COLS - ASTRAL_PANEL_WIDTH - 9))
export TERM_COLS TERM_ROWS

# Mock nvidia-smi output (10 comma-space separated fields)
nvidia_get_metrics() {
    echo "44, 5, 2834, 32607, 52.66, 0, 1440, 810, NVIDIA GeForce RTX 5090, 570.16.14"
}
# Mock the astral-hwmon driver reads
astral_available() { return 0; }
astral_get_all_currents_ma() { echo "660 680 640 700 620 720"; }
astral_get_all_voltages_mv() { echo "12180 12180 12180 12160 12180 12180"; }
astral_get_total_current_ma() { echo "4020"; }
astral_get_max_current_ma() { echo "720"; }
astral_get_balance_pct() { echo "86"; }
astral_get_connector_power_w() { echo "48.9"; }

refresh_metrics

# GPU fields parsed (and trimmed) from the mocked line
assert_eq "44" "$LIVE_GPU_TEMP" "GPU temp parsed"
assert_eq "5" "$LIVE_GPU_UTIL" "GPU utilization parsed"
assert_eq "2834" "$LIVE_GPU_USE_MEM_MIB" "VRAM used parsed"
assert_eq "32607" "$LIVE_GPU_TOTAL_MEM_MIB" "VRAM total parsed"
assert_eq "52.66" "$LIVE_GPU_POWER" "power parsed and trimmed"
assert_eq "NVIDIA GeForce RTX 5090" "$LIVE_GPU_NAME" "GPU name trimmed and intact"
assert_eq "570.16.14" "$LIVE_GPU_DRIVER" "driver version trimmed"

# Astral fields parsed
assert_eq "660" "${LIVE_ASTRAL_CURRENTS[0]}" "pin 1 current cached"
assert_eq "12160" "${LIVE_ASTRAL_VOLTAGES[3]}" "pin 4 voltage cached"
assert_eq "4020" "$LIVE_ASTRAL_TOTAL_MA" "connector total cached"
assert_eq "720" "$LIVE_ASTRAL_MAX_MA" "max pin cached"
assert_eq "48.9" "$LIVE_ASTRAL_POWER" "connector power cached"

# Panels render their key content
assert_contains "RTX 5090" "$(build_gpu_panel)" "GPU panel shows card name"
assert_contains "P1" "$(build_astral_panel)" "connector panel shows pin rows"
assert_contains "4020 mA" "$(build_astral_panel)" "connector panel shows total"
assert_contains "Connector:" "$(build_sensor_bar)" "sensor bar shows connector draw"
assert_contains "NVIDIA Dashboard" "$(build_header)" "header renders"

# The dashboard degrades when the astral driver is absent
astral_available() { return 1; }
refresh_metrics
assert_eq "0" "${#LIVE_ASTRAL_CURRENTS[@]}" "no astral -> no cached currents"
assert_contains "not loaded" "$(build_astral_panel)" "panel says the driver is missing"

rm "$TMP_DASHBOARD"
