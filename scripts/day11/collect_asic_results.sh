#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$HOME/projects/ASTRA-FT"

cd "$PROJECT_ROOT"

OUTPUT_DIR="reports/day11"
mkdir -p "$OUTPUT_DIR"

RUN_DIR="$(find asic/openlane -type d -name "RUN*" | sort | tail -n 1)"

if [[ -z "$RUN_DIR" ]]; then

    echo "ERROR: No OpenLane RUN directory found."
    exit 1

fi

echo "=========================================="
echo "ASTRA-FT ASIC RESULT COLLECTION"
echo "=========================================="

echo
echo "RUN DIRECTORY:"
echo "$RUN_DIR"

echo
echo "=========================================="
echo "1. RUN DIRECTORY STRUCTURE"
echo "=========================================="

find "$RUN_DIR" -maxdepth 3 -type d | sort \
    > "$OUTPUT_DIR/run_directory_structure.txt"

cat "$OUTPUT_DIR/run_directory_structure.txt"

echo
echo "=========================================="
echo "2. REPORT FILES"
echo "=========================================="

find "$RUN_DIR" -type f \
    | grep -Ei "report|metrics|csv|stat|area|timing" \
    > "$OUTPUT_DIR/report_file_inventory.txt" || true

cat "$OUTPUT_DIR/report_file_inventory.txt"

echo
echo "=========================================="
echo "3. GDS FILES"
echo "=========================================="

find "$RUN_DIR" -type f -name "*.gds" \
    > "$OUTPUT_DIR/gds_inventory.txt" || true

cat "$OUTPUT_DIR/gds_inventory.txt"

echo
echo "=========================================="
echo "4. NETLIST FILES"
echo "=========================================="

find "$RUN_DIR" -type f -name "*.v" \
    > "$OUTPUT_DIR/netlist_inventory.txt" || true

cat "$OUTPUT_DIR/netlist_inventory.txt"

echo
echo "=========================================="
echo "5. DEF FILES"
echo "=========================================="

find "$RUN_DIR" -type f -name "*.def" \
    > "$OUTPUT_DIR/def_inventory.txt" || true

cat "$OUTPUT_DIR/def_inventory.txt"

echo
echo "=========================================="
echo "6. LEF FILES"
echo "=========================================="

find "$RUN_DIR" -type f -name "*.lef" \
    > "$OUTPUT_DIR/lef_inventory.txt" || true

cat "$OUTPUT_DIR/lef_inventory.txt"

echo
echo "=========================================="
echo "7. TIMING/AREA/UTILIZATION SEARCH"
echo "=========================================="

grep -RniE \
    "WNS|TNS|slack|area|utilization|density|wirelength|congestion" \
    "$RUN_DIR" 2>/dev/null \
    > "$OUTPUT_DIR/metrics_search.txt" || true

head -n 200 "$OUTPUT_DIR/metrics_search.txt"

echo
echo "=========================================="
echo "8. WARNING/ERROR SEARCH"
echo "=========================================="

grep -RniE \
    "warning|error|failed|fatal|violation" \
    "$RUN_DIR" 2>/dev/null \
    > "$OUTPUT_DIR/warning_error_search.txt" || true

head -n 200 "$OUTPUT_DIR/warning_error_search.txt"

echo
echo "=========================================="
echo "COLLECTION COMPLETE"
echo "=========================================="

echo "Reports saved to:"
echo "$OUTPUT_DIR"
