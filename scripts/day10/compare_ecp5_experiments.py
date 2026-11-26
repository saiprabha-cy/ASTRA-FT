#!/usr/bin/env python3

import csv
import json
from pathlib import Path
from collections import Counter


INPUT_DIR = Path("reports/fpga/day10")
OUTPUT_FILE = Path("reports/day10/ecp5_resource_comparison.csv")


def extract_cells(filename):

    with open(filename, "r") as f:
        design = json.load(f)

    counts = Counter()

    for module in design.get("modules", {}).values():

        for cell in module.get("cells", {}).values():

            counts[cell.get("type", "UNKNOWN")] += 1

    return counts


def main():

    files = sorted(INPUT_DIR.glob("*.json"))

    if not files:
        print("No FPGA JSON files found.")
        return

    all_results = {}

    all_types = set()

    for filename in files:

        counts = extract_cells(filename)

        experiment = filename.stem

        all_results[experiment] = counts

        all_types.update(counts.keys())

    all_types = sorted(all_types)

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with open(OUTPUT_FILE, "w", newline="") as csvfile:

        writer = csv.writer(csvfile)

        writer.writerow(
            ["experiment", "total_cells"] + all_types
        )

        for experiment, counts in sorted(
            all_results.items()
        ):

            total = sum(counts.values())

            row = [
                experiment,
                total
            ]

            row.extend(
                counts.get(cell_type, 0)
                for cell_type in all_types
            )

            writer.writerow(row)

    print("============================================")
    print("FPGA RESOURCE COMPARISON")
    print("============================================")

    for experiment, counts in sorted(
        all_results.items()
    ):

        print(f"\n{experiment}")

        print("Total mapped cells:", sum(counts.values()))

        for cell_type, count in sorted(counts.items()):

            print(
                f"  {cell_type:25s} "
                f"{count:8d}"
            )

    print("\nCSV written:")
    print(OUTPUT_FILE)


if __name__ == "__main__":
    main()