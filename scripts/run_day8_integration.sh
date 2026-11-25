
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p sim/logs sim/waveforms

echo "=============================================="
echo " ASTRA-FT DAY 8 FULL INTEGRATION"
echo "=============================================="

iverilog -g2012 -Wall \
    -o sim_astra_integration \
    rtl/tmr/replica_core.sv \
    rtl/tmr/majority_voter.sv \
    rtl/tmr/astra_tmr_subsystem.sv \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv \
    rtl/scrubber/ecc_scrubber_32.sv \
    rtl/recovery/watchdog_recovery_fsm.sv \
    rtl/top/astra_ft_system.sv \
    tb/integration/tb_astra_ft_system.sv

vvp sim_astra_integration | tee sim/logs/day8_integration.log

if grep -q "INTEGRATION STATUS: PASS" sim/logs/day8_integration.log; then
    echo "DAY 8 INTEGRATION: VERIFIED PASS"
else
    echo "DAY 8 INTEGRATION: FAILED"
    exit 1
fi
