# ASTRA-FT Day 10
# FPGA Implementation Analysis and Optimization

## 1. Objective

Analyze ECP5-targeted synthesis results and evaluate
resource mapping tradeoffs.

## 2. Baseline

- Top module: astra_ft_system
- Target architecture: Lattice ECP5
- Tool: Yosys
- FPGA hardware: Not used
- Implementation stage: FPGA synthesis/mapping

## 3. Baseline Resource Results

| Resource | Count |
|----------|------:|
| LUT4 | |
| TRELLIS_FF | |
| PFUMX | |
| CCU2C | |
| DP16KD | |
| MULT18X18D | |

## 4. Generic Synthesis Baseline

| Module | Generic Cells |
|--------|--------------:|
| replica_core | 1125 |
| astra_tmr_subsystem | 4139 |
| ecc_memory_32 | 3430 |
| ecc_scrubber_32 | 1184 |
| watchdog_recovery_fsm | 514 |
| astra_ft_system | 9299 |

## 5. FPGA Architecture Mapping

Describe LUT mapping, FF mapping, carry-chain use,
memory implementation, and mux logic.

## 6. Experiments

| Experiment | Option | LUT | FF | Carry | BRAM | Total |
|------------|--------|----:|---:|------:|-----:|------:|
| Baseline | Default | | | | | |
| EXP-A | -noccu2 | | | | | |
| EXP-B | -nodffe | | | | | |
| EXP-C | -nobram | | | | | |
| EXP-D | -nodsp | | | | | |

## 7. Interpretation

Explain the tradeoffs observed.

## 8. Limitations

- No FPGA board used
- No bitstream generated
- No physical implementation validated
- No measured timing on hardware
- No physical fault testing
- Synthesis results are estimates from the selected FPGA architecture

## 9. Conclusion

Summarize the resource architecture and the results
of the mapping experiments.
