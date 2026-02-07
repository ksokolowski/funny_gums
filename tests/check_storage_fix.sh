#!/usr/bin/env bash
source lib/mod/storage/storage.sh

if type get_root_disk_usage_live &>/dev/null; then
    echo "SUCCESS: get_root_disk_usage_live found."
else
    echo "FAILURE: get_root_disk_usage_live missing."
    exit 1
fi
