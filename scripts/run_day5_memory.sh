#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/logs sim/waveforms

echo "=============================================="
echo " ASTRA-FT DAY 5 ECC MEMORY"
echo "=============================================="

iverilog -g2012 -Wall \
    -o sim_ecc_memory \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv \
    tb/integration/tb_ecc_memory_32.sv

vvp sim_ecc_memory | tee sim/logs/day5_memory.log

if grep -q "MEMORY STATUS: PASS" sim/logs/day5_memory.log; then
    echo "DAY 5 MEMORY: VERIFIED PASS"
else
    echo "DAY 5 MEMORY: FAILED"
    exit 1
fi
