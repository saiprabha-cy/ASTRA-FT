
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports/synthesis reports/fpga sim/logs

if ! command -v yosys >/dev/null 2>&1; then
    echo "ERROR: Yosys is not installed."
    exit 1
fi

echo "=============================================="
echo " ASTRA-FT DAY 9 GENERIC RTL SYNTHESIS"
echo "=============================================="

run_synthesis() {
    local top="$1"
    shift

    local sources=("$@")
    local report="reports/synthesis/${top}_synthesis.txt"
    local json="reports/synthesis/${top}_synth.json"
    local netlist="reports/synthesis/${top}_synth.v"
    local log="sim/logs/day9_${top}.log"

    echo ""
    echo "=============================================="
    echo " SYNTHESIS TOP: ${top}"
    echo "=============================================="

    yosys -p "
        read_verilog -sv ${sources[*]}
        hierarchy -check -top ${top}
        synth -top ${top}
        check
        stat
        write_json ${json}
        write_verilog ${netlist}
    " 2>&1 | tee "${log}"

    cp "${log}" "${report}"

    echo "REPORT: ${report}"
    echo "JSON  : ${json}"
    echo "NETLIST: ${netlist}"
}

# --------------------------------------------------
# Single-replica baseline
# --------------------------------------------------

run_synthesis replica_core \
    rtl/tmr/replica_core.sv
    
# --------------------------------------------------
# TMR individual subsystem
# --------------------------------------------------

run_synthesis astra_tmr_subsystem \
    rtl/tmr/replica_core.sv \
    rtl/tmr/majority_voter.sv \
    rtl/tmr/astra_tmr_subsystem.sv

# --------------------------------------------------
# ECC memory
# --------------------------------------------------

run_synthesis ecc_memory_32 \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv

# --------------------------------------------------
# ECC scrubber controller
# --------------------------------------------------

run_synthesis ecc_scrubber_32 \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/scrubber/ecc_scrubber_32.sv

# --------------------------------------------------
# Watchdog recovery controller
# --------------------------------------------------

run_synthesis watchdog_recovery_fsm \
    rtl/recovery/watchdog_recovery_fsm.sv

# --------------------------------------------------
# Full integrated ASTRA-FT system
# --------------------------------------------------

run_synthesis astra_ft_system \
    rtl/tmr/replica_core.sv \
    rtl/tmr/majority_voter.sv \
    rtl/tmr/astra_tmr_subsystem.sv \
    rtl/ecc/secded_encoder_32.sv \
    rtl/ecc/secded_decoder_32.sv \
    rtl/memory/ecc_memory_32.sv \
    rtl/scrubber/ecc_scrubber_32.sv \
    rtl/recovery/watchdog_recovery_fsm.sv \
    rtl/top/astra_ft_system.sv

echo ""
echo "=============================================="
echo " DAY 9 SYNTHESIS COMPLETED"
echo "=============================================="
echo "Reports:"
echo " reports/synthesis/"
