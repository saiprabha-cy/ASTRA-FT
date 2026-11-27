#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/logs
mkdir -p sim/waveforms

echo "=============================================="
echo " ASTRA-FT DAY 4 SECDED VERIFICATION"
echo "=============================================="

iverilog -g2012 -Wall \
    -o sim_secded \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    tb/unit/tb_secded_32.sv

echo ""
echo "Running SECDED verification..."
echo ""

vvp sim_secded | tee sim/logs/day4_secded.log

if grep -q "SECDED STATUS: PASS" sim/logs/day4_secded.log; then
    echo ""
    echo "DAY 4 SECDED: VERIFIED PASS"
else
    echo ""
    echo "DAY 4 SECDED: FAILED"
    exit 1
fi
