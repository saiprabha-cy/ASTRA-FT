
# ASTRA-FT Day 9 — RTL Synthesis and FPGA Analysis

## 1. Objective

Evaluate synthesizability and estimate generic hardware structure
for ASTRA-FT.

## 2. Tools

- Yosys version:
- Verilator version:
- Ubuntu version:
- WSL version/environment:

## 3. Synthesized Targets

- replica_core
- astra_tmr_subsystem
- ecc_memory_32
- ecc_scrubber_32
- watchdog_recovery_fsm
- astra_ft_system

## 4. Generic Synthesis Results

| Design | Cell count | Sequential cells | Combinational cells | Notes |
|---|---:|---:|---:|---|
| replica_core | | | | |
| astra_tmr_subsystem | | | | |
| ecc_memory_32 | | | | |
| ecc_scrubber_32 | | | | |
| watchdog_recovery_fsm | | | | |
| astra_ft_system | | | | |

## 5. TMR Overhead

Compare replica_core against astra_tmr_subsystem.

Discuss:

- Replicated computation
- Voting logic
- Mismatch detection
- Resource overhead
- Fault-tolerance benefit
- Common-mode limitations

## 6. ECC Memory Analysis

- Payload width: 32 bits
- ECC codeword width: 39 bits
- Memory depth: 16 words
- Payload storage: 512 bits
- ECC storage: 112 bits
- Total codeword storage: 624 bits

Theoretical ECC storage overhead relative to payload storage:

7 / 32 = 21.875%

Actual synthesized resource usage must be taken from the synthesis reports.

## 7. Scrubber Analysis

Describe:

- FSM
- Scan address counter
- Corrected error counter
- Uncorrectable error counter
- Decoder/encoder datapath
- Writeback control

## 8. Watchdog Analysis

Describe:

- Heartbeat monitor
- Timeout counter
- Recovery timeout counter
- Retry counter
- FSM
- Safe mode output

## 9. Integrated Architecture

Describe the combined TMR/ECC/scrubber/watchdog architecture.

## 10. FPGA Mapping

- ECP5 mapping attempted: Yes / No
- Tool command:
- Target:
- Mapping result:
- Resource report:

## 11. Timing

- Timing constraints created: Yes / No
- Placement performed: Yes / No
- Routing performed: Yes / No
- Timing analysis performed: Yes / No

Do not claim timing closure without a genuine constrained timing report.

## 12. Warnings and Limitations

Document warnings, synthesis limitations and unresolved issues.

## 13. Conclusion

Summarize only what the generated reports and simulations demonstrate.
