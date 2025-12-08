#!/bin/bash
echo "[MOCK] DRAM.py running..."
# If annotate: -o OUT_DIR
# If distill: -o OUT_DIR
OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-o" ]]; then
        OUTPUT_DIR="$2"
    fi
    shift
done
mkdir -p "$OUTPUT_DIR"
touch "$OUTPUT_DIR/annotations.tsv"
touch "$OUTPUT_DIR/product.html"
exit 0
