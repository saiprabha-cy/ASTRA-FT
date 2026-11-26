#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$HOME/projects/ASTRA-FT"
ASIC_DIR="$PROJECT_ROOT/asic/openlane"
SRC_DIR="$ASIC_DIR/src"

mkdir -p "$SRC_DIR"

RTL_FILES=(
    "rtl/tmr/replica_core.sv"
    "rtl/tmr/majority_voter.sv"
    "rtl/tmr/astra_tmr_subsystem.sv"
    "rtl/ecc/secded_encoder_32.sv"
    "rtl/ecc/secded_decoder_32.sv"
    "rtl/memory/ecc_memory_32.sv"
    "rtl/scrubber/ecc_scrubber_32.sv"
    "rtl/recovery/watchdog_recovery_fsm.sv"
    "rtl/top/astra_ft_system.sv"
)

echo "======================================"
echo "Preparing ASTRA-FT ASIC RTL sources"
echo "======================================"

for relative_file in "${RTL_FILES[@]}"; do

    source_file="$PROJECT_ROOT/$relative_file"
    filename="$(basename "$relative_file")"
    link_file="$SRC_DIR/$filename"

    if [[ ! -f "$source_file" ]]; then

        echo "ERROR: Missing source: $source_file"
        exit 1

    fi

    ln -sf "$source_file" "$link_file"

    echo "Linked:"
    echo "  $source_file"
    echo "  -> $link_file"

done

echo
echo "======================================"
echo "SOURCE CHECK"
echo "======================================"

for file in "$SRC_DIR"/*.sv; do

    if [[ -f "$file" ]]; then

        echo "PASS: $file"

    else

        echo "FAIL: $file"

    fi

done

echo
echo "ASIC source preparation complete."
