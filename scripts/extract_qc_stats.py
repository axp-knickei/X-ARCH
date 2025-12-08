#!/usr/bin/env python3
import json
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Extract QC statistics from fastp JSON report.")
    parser.add_argument("json_file", help="Path to the fastp JSON output file")
    args = parser.parse_args()

    try:
        with open(args.json_file) as f:
            data = json.load(f)
        
        print("\n=== QC SUMMARY ===")
        print(f"Reads before filtering: {data['summary']['before_filtering']['total_reads']}")
        print(f"Reads after filtering: {data['summary']['after_filtering']['total_reads']}")
        print(f"Q30 rate (after): {data['summary']['after_filtering']['q30_rate']:.2%}")
        print(f"GC content: {data['summary']['after_filtering']['gc_content']:.2%}")
    except FileNotFoundError:
        print(f"Error: File not found: {args.json_file}", file=sys.stderr)
        sys.exit(1)
    except KeyError as e:
        print(f"Error: Missing key in JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Warning: Could not parse QC JSON: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

