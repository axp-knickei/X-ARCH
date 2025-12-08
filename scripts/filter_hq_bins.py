#!/usr/bin/env python3
import pandas as pd
import argparse
import sys
import os

def main():
    parser = argparse.ArgumentParser(description="Filter high-quality bins from CheckM2 report.")
    parser.add_argument("qc_file", help="Path to the CheckM2 quality_report.tsv file")
    parser.add_argument("--completeness", type=float, default=90.0, help="Minimum completeness threshold (default: 90.0)")
    parser.add_argument("--contamination", type=float, default=5.0, help="Maximum contamination threshold (default: 5.0)")
    args = parser.parse_args()

    if not os.path.exists(args.qc_file):
        print(f"Error: QC file not found: {args.qc_file}", file=sys.stderr)
        sys.exit(1)

    try:
        df = pd.read_csv(args.qc_file, sep='\t')
        hq_bins = df[(df['Completeness'] > args.completeness) & (df['Contamination'] < args.contamination)]
        print(f"\nHigh-Quality Bins: {len(hq_bins)}/{len(df)}")
        print(hq_bins[['Name', 'Completeness', 'Contamination']].to_string(index=False))
    except Exception as e:
        print(f"Error filtering bins: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
