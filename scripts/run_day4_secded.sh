#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

SIM="sim/tb/day4/tb_day4_secded_full.vvp"
COMPILE_LOG="sim/logs/day4/compile.log"
RUN_LOG="sim/logs/day4/full_campaign.log"

mkdir -p sim/tb/day4
mkdir -p sim/logs/day4
mkdir -p sim/waveforms

echo "=================================================="
echo " ASTRA-FT DAY 4 SECDED REGRESSION"
echo "=================================================="

echo
echo "[1/3] Compiling SECDED RTL and verification testbench..."

iverilog -g2012 -Wall \
    -s tb_day4_secded_full \
    -o "$SIM" \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    tb/day4/tb_day4_secded_full.sv \
    2>&1 | tee "$COMPILE_LOG"

echo
echo "[2/3] Running full SECDED campaign..."

vvp "$SIM" | tee "$RUN_LOG"

echo
echo "[3/3] Checking campaign result..."

if grep -Fq "DAY 4 SECDED STATUS: PASS" "$RUN_LOG"; then

    echo
    echo "=================================================="
    echo " DAY 4 REGRESSION: PASS"
    echo "=================================================="

else

    echo
    echo "=================================================="
    echo " DAY 4 REGRESSION: FAIL"
    echo "=================================================="

    exit 1

fi

echo
echo "Evidence files:"
echo "  Compile log : $COMPILE_LOG"
echo "  Run log     : $RUN_LOG"
echo "  Waveform    : sim/waveforms/day4_secded_full.vcd"
echo "  Simulation  : $SIM"

