#!/bin/bash
echo "[MOCK] quast.py running..."
# Find output dir
OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-o" ]]; then
        OUTPUT_DIR="$2"
    fi
    shift
done
mkdir -p "$OUTPUT_DIR"
touch "$OUTPUT_DIR/report.html"
exit 0
