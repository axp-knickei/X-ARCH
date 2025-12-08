#!/usr/bin/env python3
import yaml
import argparse
import sys
import os

def flatten_dict(d, parent_key='', sep='_'):
    """Flatten a nested dictionary."""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key.upper(), v)) # Convert keys to uppercase
    return dict(items)

def main():
    parser = argparse.ArgumentParser(description="Read YAML config and output as shell-friendly KEY=VALUE pairs.")
    parser.add_argument("config_file", help="Path to the YAML configuration file")
    args = parser.parse_args()

    if not os.path.exists(args.config_file):
        print(f"Error: Config file not found: {args.config_file}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(args.config_file, 'r') as f:
            config = yaml.safe_load(f)
        
        flat_config = flatten_dict(config)

        for key, value in flat_config.items():
            # Handle boolean values
            if isinstance(value, bool):
                value = "true" if value else "false"
            # Escape values for shell (simple cases for now)
            # More robust escaping might be needed for complex strings
            if isinstance(value, str):
                value = value.replace('"', '\"').replace('$', '\$').replace('`', '\`')
                print(f'{key}="{value}"')
            else:
                print(f'{key}={value}')

    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
