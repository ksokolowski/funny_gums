#!/usr/bin/env bash
# astral.sh - Per-pin 12VHPWR connector monitoring for ASUS ROG Astral cards
# Reads the astral12vhpwr hwmon device exported by the astral-hwmon driver
# (https://github.com/ksokolowski/astral-hwmon). Per the hwmon ABI, current
# attributes are milliamps and voltage attributes millivolts.
#
# Judgment thresholds mirror astral-guard's guard_limits_default so a widget
# coloured with them agrees with `astral-guard`'s verdict. Sources: ASUS Power
# Detector+ limits, the 12V-2x6 per-pin rating, ATX 12V tolerance and WireView
# Pro II imbalance rules (astral-hwmon docs/GUARD-DESIGN.md).
# shellcheck disable=SC2034

[[ -n "${_SYSTEM_ASTRAL_LOADED:-}" ]] && return 0
_SYSTEM_ASTRAL_LOADED=1

_ASTRAL_HWMON_NAME="astral12vhpwr"
_ASTRAL_HWMON_DIR="" # Cached on first query; empty string = not found

# Per-pin current: warning / critical / "reads ~0 A" (interesting only under load)
_ASTRAL_PIN_WARN_MA=9200
_ASTRAL_PIN_CRIT_MA=9500 # 12V-2x6 per-pin rating
_ASTRAL_PIN_OPEN_MA=500

# Per-pin voltage: ATX 12V -5% / -8%; lower is worse
_ASTRAL_VOLT_WARN_MV=11400
_ASTRAL_VOLT_CRIT_MV=11000

# Pin imbalance: min as a percentage of max — WireView Pro II's "30% difference"
# warning and its field-revised "40%" critical; lower is worse
_ASTRAL_BALANCE_WARN_PCT=70
_ASTRAL_BALANCE_CRIT_PCT=60

# Find and cache the astral12vhpwr hwmon directory.
_astral_find_hwmon() {
    local hwmon_dir="${SYSFS_HWMON_DIR:-/sys/class/hwmon}"
    local dir name
    for dir in "$hwmon_dir"/hwmon*; do
        [[ -d "$dir" ]] || continue
        name=$(cat "$dir/name" 2>/dev/null)
        if [[ "$name" == "$_ASTRAL_HWMON_NAME" ]]; then
            _ASTRAL_HWMON_DIR="$dir"
            return 0
        fi
    done
    _ASTRAL_HWMON_DIR=""
    return 1
}

# Resolve the cached hwmon dir, discovering it on first call.
astral_find_hwmon() {
    [[ -n "$_ASTRAL_HWMON_DIR" && -d "$_ASTRAL_HWMON_DIR" ]] && return 0
    _astral_find_hwmon
}

# Usage: astral_available && echo "astral connector present"
astral_available() {
    astral_find_hwmon
}

# Read one hwmon attribute, guard the file disappearing mid-detection.
_astral_read() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file" 2>/dev/null && return 0
    fi
    return 1
}

# Driver's documented cache window so callers can poll no faster than needed.
# Usage: interval=$(astral_get_update_interval_ms)
astral_get_update_interval_ms() {
    astral_available || return 1
    local raw
    raw=$(_astral_read "$_ASTRAL_HWMON_DIR/update_interval") || return 1
    [[ -n "$raw" ]] && echo "$raw"
}

# Current of one pin in mA.
# Usage: astral_get_pin_current_ma 3
astral_get_pin_current_ma() {
    local pin="$1"
    astral_available || return 1
    [[ "$pin" -ge 1 && "$pin" -le 6 ]] || return 1
    _astral_read "$_ASTRAL_HWMON_DIR/curr${pin}_input" || return 1
}

# Voltage of one pin in mV (pin N pairs with in$((N-1)) per the driver's labels).
# Usage: astral_get_pin_voltage_mv 3
astral_get_pin_voltage_mv() {
    local pin="$1"
    astral_available || return 1
    [[ "$pin" -ge 1 && "$pin" -le 6 ]] || return 1
    _astral_read "$_ASTRAL_HWMON_DIR/in$((pin - 1))_input" || return 1
}

# All six per-pin currents in mA, once per read.
astral_get_all_currents_ma() {
    astral_available || return 1
    local i values=""
    for i in 1 2 3 4 5 6; do
        [[ -n "$values" ]] && values+=" "
        values+="$(_astral_read "$_ASTRAL_HWMON_DIR/curr${i}_input" || echo 0)"
    done
    echo "$values"
}

# All six per-pin voltages in mV.
astral_get_all_voltages_mv() {
    astral_available || return 1
    local i values=""
    for i in 0 1 2 3 4 5; do
        [[ -n "$values" ]] && values+=" "
        values+="$(_astral_read "$_ASTRAL_HWMON_DIR/in${i}_input" || echo 0)"
    done
    echo "$values"
}

# Sum of the six pin currents in mA — the connector's total draw.
astral_get_total_current_ma() {
    astral_available || return 1
    local i total=0 value
    for i in 1 2 3 4 5 6; do
        value=$(_astral_read "$_ASTRAL_HWMON_DIR/curr${i}_input") || return 1
        total=$((total + value))
    done
    echo "$total"
}

# Heaviest-loaded pin in mA.
astral_get_max_current_ma() {
    astral_available || return 1
    local i max=0 value
    for i in 1 2 3 4 5 6; do
        value=$(_astral_read "$_ASTRAL_HWMON_DIR/curr${i}_input") || return 1
        [[ "$value" -gt "$max" ]] && max=$value
    done
    echo "$max"
}

# Pin balance: the lowest pin as a percentage of the highest. 100 = perfectly
# balanced; a dropping value is the imbalance WireView Pro II flags.
astral_get_balance_pct() {
    astral_available || return 1
    local i min="" max=0 value
    for i in 1 2 3 4 5 6; do
        value=$(_astral_read "$_ASTRAL_HWMON_DIR/curr${i}_input") || return 1
        [[ -z "$min" || "$value" -lt "$min" ]] && min=$value
        [[ "$value" -gt "$max" ]] && max=$value
    done
    if [[ "$max" -gt 0 ]]; then
        echo $((min * 100 / max))
    else
        echo 100
    fi
}

# Approximate connector power from the per-pin samples: Σ I_i × V_i, in watts.
astral_get_connector_power_w() {
    astral_available || return 1
    local i watts=0 curr_mv volt_mv
    for i in 1 2 3 4 5 6; do
        curr_mv=$(_astral_read "$_ASTRAL_HWMON_DIR/curr${i}_input") || return 1
        volt_mv=$(_astral_read "$_ASTRAL_HWMON_DIR/in$((i - 1))_input") || return 1
        watts=$((watts + curr_mv * volt_mv))
    done
    # P = Σ(mA × mV) / 1e6
    awk -v w="$watts" 'BEGIN { printf "%.1f", w / 1000000 }'
}

# Per-pin current status: "ok" | "warn" | "crit"
astral_pin_current_status() {
    local value
    value=$(astral_get_pin_current_ma "$1") || return 1
    astral_classify_current_ma "$value"
}

# Per-pin voltage status — sagging rail, so below a floor is bad.
astral_pin_voltage_status() {
    local value
    value=$(astral_get_pin_voltage_mv "$1") || return 1
    astral_classify_voltage_mv "$value"
}

# Connector imbalance status from the min/max ratio.
astral_balance_status() {
    local value
    value=$(astral_get_balance_pct) || return 1
    astral_classify_balance_pct "$value"
}

# Pure classifiers on an already-read sample, so a cache-driven dashboard need
# not re-read sysfs once per pin. Same thresholds as the *_status siblings.
# Usage: astral_classify_current_ma 9300 -> warn
astral_classify_current_ma() {
    local value="$1"
    [[ "$value" -ge "$_ASTRAL_PIN_CRIT_MA" ]] && {
        echo crit
        return
    }
    [[ "$value" -ge "$_ASTRAL_PIN_WARN_MA" ]] && {
        echo warn
        return
    }
    echo ok
}

# Usage: astral_classify_voltage_mv 11200 -> warn (rail sag)
astral_classify_voltage_mv() {
    local value="$1"
    [[ "$value" -lt "$_ASTRAL_VOLT_CRIT_MV" ]] && {
        echo crit
        return
    }
    [[ "$value" -lt "$_ASTRAL_VOLT_WARN_MV" ]] && {
        echo warn
        return
    }
    echo ok
}

# Usage: astral_classify_balance_pct 64 -> warn
astral_classify_balance_pct() {
    local value="$1"
    [[ "$value" -lt "$_ASTRAL_BALANCE_CRIT_PCT" ]] && {
        echo crit
        return
    }
    [[ "$value" -lt "$_ASTRAL_BALANCE_WARN_PCT" ]] && {
        echo warn
        return
    }
    echo ok
}
