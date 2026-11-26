#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$HOME/projects/ASTRA-FT"

cd "$PROJECT_ROOT"

RTL_LIST="rtl/tmr/replica_core.sv rtl/tmr/majority_voter.sv rtl/tmr/astra_tmr_subsystem.sv rtl/ecc/secded_encoder_32.sv rtl/ecc/secded_decoder_32.sv rtl/memory/ecc_memory_32.sv rtl/scrubber/ecc_scrubber_32.sv rtl/recovery/watchdog_recovery_fsm.sv rtl/top/astra_ft_system.sv"

mkdir -p reports/fpga/day10
mkdir -p sim/logs/day10

run_experiment() {
    local EXP_NAME="$1"
    local OPTION="$2"

    local JSON_FILE="reports/fpga/day10/${EXP_NAME}.json"
    local LOG_FILE="sim/logs/day10/${EXP_NAME}.log"

    echo
    echo "=================================================="
    echo "Running experiment: ${EXP_NAME}"
    echo "Option: ${OPTION:-DEFAULT}"
    echo "=================================================="

    if [[ -z "$OPTION" ]]; then
        yosys -p "
            read_verilog -sv ${RTL_LIST}
            hierarchy -check -top astra_ft_system
            synth_ecp5 -top astra_ft_system -json ${JSON_FILE}
            stat
        " 2>&1 | tee "$LOG_FILE"
    else
        yosys -p "
            read_verilog -sv ${RTL_LIST}
            hierarchy -check -top astra_ft_system
            synth_ecp5 -top astra_ft_system ${OPTION} -json ${JSON_FILE}
            stat
        " 2>&1 | tee "$LOG_FILE"
    fi

    if [[ ! -f "$JSON_FILE" ]]; then
        echo "ERROR: JSON output missing for ${EXP_NAME}"
        exit 1
    fi

    python3 -m json.tool "$JSON_FILE" > /dev/null

    echo "Experiment ${EXP_NAME}: JSON VALID"
}

run_experiment "baseline" ""
run_experiment "exp_noccu2" "-noccu2"
run_experiment "exp_nodffe" "-nodffe"
run_experiment "exp_nobram" "-nobram"
run_experiment "exp_nodsp" "-nodsp"

echo
echo "=================================================="
echo "ALL EXPERIMENTS FINISHED"
echo "=================================================="