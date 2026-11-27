#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/tb/day3 sim/logs/day3 sim/waveforms

echo "================================================"
echo " ASTRA-FT DAY 3 FAULT CAMPAIGN"
echo "================================================"

echo
echo "[1/3] Checking required tools..."

command -v iverilog >/dev/null 2>&1 || {
    echo "ERROR: iverilog is not installed."
    exit 1
}

command -v vvp >/dev/null 2>&1 || {
    echo "ERROR: vvp is not installed."
    exit 1
}

echo "Icarus Verilog: $(iverilog -V 2>&1 | head -n 1)"
echo "VVP: available"

echo
echo "[2/3] Compiling TMR fault campaign..."

iverilog -g2012 -Wall \
    -s tb_tmr_fault_campaign \
    -o sim/tb/day3/tb_tmr_fault_campaign.vvp \
    rtl/tmr/replica_core.sv \
    rtl/tmr/majority_voter.sv \
    rtl/tmr/astra_tmr_subsystem.sv \
    tb/fault_campaign/tb_tmr_fault_campaign.sv \
    2>&1 | tee sim/logs/day3/compile.log

echo
echo "[3/3] Running fault campaign..."

vvp sim/tb/day3/tb_tmr_fault_campaign.vvp \
    2>&1 | tee sim/logs/day3/fault_campaign.log

echo
echo "================================================"
echo " VERIFYING CAMPAIGN RESULT"
echo "================================================"

if grep -q "DAY 3 CAMPAIGN: PASS" \
    sim/logs/day3/fault_campaign.log; then

    echo "PASS: Day 3 fault campaign completed successfully."

else

    echo "FAIL: Day 3 campaign PASS marker not found."
    exit 1

fi

echo
echo "Generated files:"
echo "  sim/tb/day3/tb_tmr_fault_campaign.vvp"
echo "  sim/logs/day3/compile.log"
echo "  sim/logs/day3/fault_campaign.log"
echo "  sim/waveforms/tmr_fault_campaign.vcd"

echo
echo "DAY 3 RUNNER: PASS"
