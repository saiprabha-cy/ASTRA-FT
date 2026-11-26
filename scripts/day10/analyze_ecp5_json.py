#!/usr/bin/env python3

import json
import sys
from collections import Counter
from pathlib import Path


def analyze_json(filename):
    path = Path(filename)

    if not path.exists():
        print(f"ERROR: File does not exist: {path}")
        return None

    with path.open("r") as file:
        design = json.load(file)

    total_counts = Counter()
    module_counts = {}

    modules = design.get("modules", {})

    for module_name, module in modules.items():
        counts = Counter()

        cells = module.get("cells", {})

        for cell_name, cell in cells.items():
            cell_type = cell.get("type", "UNKNOWN")
            counts[cell_type] += 1
            total_counts[cell_type] += 1

        module_counts[module_name] = counts

    return total_counts, module_counts


def print_report(filename):
    result = analyze_json(filename)

    if result is None:
        return

    total_counts, module_counts = result

    print("=" * 70)
    print(f"FILE: {filename}")
    print("=" * 70)

    print("\nCELL COUNTS:")
    print("-" * 70)

    for cell_type, count in sorted(total_counts.items()):
        print(f"{cell_type:30s} {count:10d}")

    print("\nTOTAL CELLS:")
    print("-" * 70)

    print(sum(total_counts.values()))

    print("\nMODULE BREAKDOWN:")
    print("-" * 70)

    for module_name, counts in module_counts.items():
        print(f"\nMODULE: {module_name}")

        for cell_type, count in sorted(counts.items()):
            print(f"  {cell_type:25s} {count:8d}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            "Usage: python3 analyze_ecp5_json.py "
            "<synthesis_json>"
        )
        sys.exit(1)

    print_report(sys.argv[1])
