#!/usr/bin/env bash
# test_storage.sh - Unit tests for storage monitoring module

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

test_file_start "storage.sh"

# Mock lsblk command
lsblk() {
    # Check if JSON output requested
    if [[ "$*" == *"-J"* ]]; then
        cat <<EOF
{
   "blockdevices": [
      {"name":"sda", "size":500107862016, "model":"Samsung SSD 860", "rota":false, "tran":"sata", "type":"disk"},
      {"name":"nvme0n1", "size":1000204886016, "model":"Samsung SSD 970 EVO", "rota":false, "tran":"nvme", "type":"disk"},
      {"name":"sr0", "size":1073741312, "model":"DVD-ROM", "rota":true, "tran":"sata", "type":"rom"},
      {"name":"zram0", "size":4294967296, "model":null, "rota":false, "tran":null, "type":"disk"},
      {"name":"loop0", "size":104857600, "model":null, "rota":false, "tran":null, "type":"loop"}
   ]
}
EOF
    else
        # Fallback for non-JSON calls if any
        command lsblk "$@"
    fi
}

# Source library under test
source "$PROJECT_DIR/lib/mod/storage/storage.sh"

# Test get_physical_drives
drives=$(get_physical_drives)

# 1. Should identify sda as SSD
((TESTS_RUN++))
if [[ "$drives" == *"sda|500107862016|Samsung SSD 860|ssd"* ]]; then
    echo "  ${GREEN}✓${RESET} Identified sda as SSD"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Failed to identify sda correctly (got: $drives)"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("storage.sh: Should identify sda as SSD")
fi

# 2. Should identify nvme0n1 as nvme
((TESTS_RUN++))
if [[ "$drives" == *"nvme0n1|1000204886016|Samsung SSD 970 EVO|nvme"* ]]; then
    echo "  ${GREEN}✓${RESET} Identified nvme0n1 as nvme"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Failed to identify nvme0n1 correctly"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("storage.sh: Should identify nvme0n1 as nvme")
fi

# 3. Should NOT include sr0 (rom)
((TESTS_RUN++))
if [[ "$drives" != *"sr0"* ]]; then
    echo "  ${GREEN}✓${RESET} Excluded sr0 (rom)"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Failed to exclude sr0"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("storage.sh: Should exclude ROM devices")
fi

# 4. Should NOT include loop0
((TESTS_RUN++))
if [[ "$drives" != *"loop0"* ]]; then
    echo "  ${GREEN}✓${RESET} Excluded loop0 (loop)"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Failed to exclude loop0"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("storage.sh: Should exclude loop devices")
fi

# 5. BUG FIX VERIFICATION: Should NOT include zram0
((TESTS_RUN++))
if [[ "$drives" != *"zram0"* ]]; then
    echo "  ${GREEN}✓${RESET} Excluded zram0 (zram)"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${RESET} Failed to exclude zram0 (Bug Fix Verification)"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("storage.sh: Should exclude ZRAM devices")
fi
