#!/bin/bash
echo "[MOCK] spades.py running..."
# Argument parsing to find output dir
OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o) OUTPUT_DIR="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ -n "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
    touch "$OUTPUT_DIR/contigs.fasta"
    # echo dummy contig > "$OUTPUT_DIR/contigs.fasta"
    echo ">contig_1_length_1000" > "$OUTPUT_DIR/contigs.fasta"
    echo "ATGC" >> "$OUTPUT_DIR/contigs.fasta"
fi
exit 0
