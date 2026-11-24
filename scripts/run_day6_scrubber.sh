#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/logs sim/waveforms

echo "=============================================="
echo " ASTRA-FT DAY 6 MEMORY SCRUBBER"
echo "=============================================="

iverilog -g2012 -Wall \
    -o sim_ecc_scrubber \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv \
    rtl/scrubber/ecc_scrubber_32.sv \
    tb/integration/tb_ecc_scrubber_32.sv

vvp sim_ecc_scrubber | tee sim/logs/day6_scrubber.log

if grep -q "SCRUBBER STATUS: PASS" sim/logs/day6_scrubber.log; then
    echo "DAY 6 SCRUBBER: VERIFIED PASS"
else
    echo "DAY 6 SCRUBBER: FAILED"
    exit 1
fi
