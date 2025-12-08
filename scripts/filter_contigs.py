#!/usr/bin/env python3
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Filter contigs by length.")
    parser.add_argument("-i", "--input", required=True, help="Input FASTA file")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file")
    parser.add_argument("--min_length", type=int, default=200, help="Minimum contig length (default: 200)")
    args = parser.parse_args()

    count_kept = 0
    count_removed = 0
    min_length = args.min_length

    try:
        with open(args.input) as f_in, open(args.output, 'w') as f_out:
            seq_id = None
            seq = []
            
            for line in f_in:
                line = line.rstrip()
                if line.startswith('>'):
                    if seq_id and len(''.join(seq)) >= min_length:
                        f_out.write(f'{seq_id}\n')
                        f_out.write(''.join(seq) + '\n')
                        count_kept += 1
                    elif seq_id:
                        count_removed += 1
                    seq_id = line
                    seq = []
                else:
                    seq.append(line)
            
            # Process last sequence
            if seq_id and len(''.join(seq)) >= min_length:
                f_out.write(f'{seq_id}\n')
                f_out.write(''.join(seq) + '\n')
                count_kept += 1
            elif seq_id:
                count_removed += 1

        print(f"Filtered {args.input}: Kept {count_kept}, Removed {count_removed} contigs (<{min_length}bp)")
    
    except Exception as e:
        print(f"Error filtering contigs: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
