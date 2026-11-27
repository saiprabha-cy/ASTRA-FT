#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SIM="sim/tb/day5/tb_day5_ecc_memory_full.vvp"
COMPILE_LOG="sim/logs/day5/full_compile.log"
RUN_LOG="sim/logs/day5/full_campaign.log"

mkdir -p sim/tb/day5 sim/logs/day5 sim/waveforms/day5

echo "=================================================="
echo " ASTRA-FT DAY 5 ECC MEMORY REGRESSION"
echo "=================================================="

echo
echo "[1/3] Compiling ECC memory and verification testbench..."

iverilog -g2012 -Wall \
    -s tb_day5_ecc_memory_full \
    -o "$SIM" \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv \
    tb/day5/tb_day5_ecc_memory_full.sv \
    2>&1 | tee "$COMPILE_LOG"

echo
echo "[2/3] Running ECC memory campaign..."

vvp "$SIM" | tee "$RUN_LOG"

echo
echo "[3/3] Checking campaign result..."

if grep -Fq "DAY 5 ECC MEMORY STATUS: PASS" "$RUN_LOG"; then
    echo
    echo "=================================================="
    echo " DAY 5 ECC MEMORY REGRESSION: PASS"
    echo "=================================================="
else
    echo
    echo "DAY 5 ECC MEMORY REGRESSION: FAIL"
    exit 1
fi

echo
echo "Evidence files:"
echo "  Compile log : $COMPILE_LOG"
echo "  Run log     : $RUN_LOG"
echo "  Waveform    : sim/waveforms/day5_ecc_memory_full.vcd"
echo "  Simulation  : $SIM"
