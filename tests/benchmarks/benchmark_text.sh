#!/usr/bin/env bash
# benchmark_text.sh - Benchmark text processing functions

source lib/core/text.sh
source lib/core/colors.sh

# Test strings
SHORT="Hello"
MEDIUM="Hello World with some formatting and emojis 🚀"
LONG="This is a much longer string with multiple emojis 🌈 and some ANSI colors ${RED}RED${RESET} and ${BLUE}BLUE${RESET} to test the performance of the visual_width function extensively."

# Benchmark function
benchmark() {
    local name="$1"
    local string="$2"
    local count="$3"
    local start_time
    local end_time
    local duration

    echo -n "Benchmarking $name ($count iterations)... "

    start_time=$(date +%s%N)
    for ((i=0; i<count; i++)); do
        # Call the function (discard output)
        _=$(visual_width "$string")
    done
    end_time=$(date +%s%N)

    # Calculate duration in milliseconds
    duration=$(( (end_time - start_time) / 1000000 ))
    echo "${duration}ms"
}

echo "=== Visual Width Benchmark ==="
benchmark "Short String" "$SHORT" 1000
benchmark "Medium String" "$MEDIUM" 500
benchmark "Long String" "$LONG" 100
