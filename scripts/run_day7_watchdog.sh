#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/logs sim/waveforms

echo "=============================================="
echo " ASTRA-FT DAY 7 WATCHDOG / RECOVERY FSM"
echo "=============================================="

iverilog -g2012 -Wall \
    -o sim_watchdog \
    rtl/recovery/watchdog_recovery_fsm.sv \
    tb/unit/tb_watchdog_recovery_fsm.sv

vvp sim_watchdog | tee sim/logs/day7_watchdog.log

if grep -q "WATCHDOG STATUS: PASS" sim/logs/day7_watchdog.log; then
    echo "DAY 7 WATCHDOG: VERIFIED PASS"
else
    echo "DAY 7 WATCHDOG: FAILED"
    exit 1
fi
