#!/usr/bin/env bash
# tests/verify_paths.sh - Check all library files for broken source calls
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT

errors=0
while IFS= read -r -d '' f; do
    echo "Checking $f..."
    # We use a subshell to test sourcing. We mock gum and other tools if needed.
    # But mainly we want to see if 'source' fails to find a file.
    output=$(bash -c "source '$f'" 2>&1)
    if echo "$output" | grep -q "No such file or directory\|Nie ma takiego pliku"; then
        echo "  [FAIL] $f"
        echo "         $output"
        errors=$((errors + 1))
    fi
done < <(find "$PROJECT_ROOT/lib" -name "*.sh" -print0)

if [[ $errors -eq 0 ]]; then
    echo "SUCCESS: No broken source paths found in lib/"
    exit 0
else
    echo "FAILURE: Found $errors broken source paths"
    exit 1
fi
