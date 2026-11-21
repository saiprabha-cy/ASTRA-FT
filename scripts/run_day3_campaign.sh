#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "=============================================="
echo " ASTRA-FT DAY 3 FAULT CAMPAIGN"
echo "=============================================="

mkdir -p sim/logs sim/waveforms

iverilog -g2012 -Wall \
    -o sim_fault_campaign \
    rtl/tmr/majority_voter.sv \
    rtl/tmr/replica_core.sv \
    rtl/tmr/astra_tmr_subsystem.sv \
    tb/fault_campaign/tb_tmr_fault_campaign.sv

echo ""
echo "Running simulation..."
echo ""

vvp sim_fault_campaign | tee sim/logs/day3_fault_campaign.log

if grep -q "CAMPAIGN STATUS: PASS" sim/logs/day3_fault_campaign.log; then
    echo ""
    echo "DAY 3 CAMPAIGN: VERIFIED PASS"
else
    echo ""
    echo "DAY 3 CAMPAIGN: FAILED"
    exit 1
fi
