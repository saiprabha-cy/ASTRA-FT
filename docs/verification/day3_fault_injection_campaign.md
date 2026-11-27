# ASTRA-FT — Day 3 TMR Fault-Injection Campaign

## 1. Objective

Evaluate the TMR subsystem under single-lane, multi-lane and common-mode
output fault injection.

The campaign uses the existing astra_tmr_subsystem RTL without modifying
the TMR architecture.

## 2. Verification Environment

- HDL: SystemVerilog
- Simulator: Icarus Verilog 12.0
- Testbench: tb/fault_campaign/tb_tmr_fault_campaign.sv
- DUT: rtl/tmr/astra_tmr_subsystem.sv
- Fault model: XOR masks applied to replica outputs
- Waveform: sim/waveforms/tmr_fault_campaign.vcd

## 3. Campaign Results

| Campaign | Executed | Passed | Failed |
|---|---:|---:|---:|
| Single-bit, single-lane faults | 768 | 768 | 0 |
| Randomized multi-bit, single-lane faults | 200 | 200 | 0 |
| Two-lane characterization | 100 | 100 | 0 |
| Common-mode characterization | 8 | 8 | 0 |
| Total | 1076 | 1076 | 0 |

## 4. Single-Lane Fault Results

All 768 single-bit cases preserved the golden output.

The campaign covered:
- 8 supported opcodes
- 32 output bit positions
- 3 replica lanes

All 200 randomized multi-bit single-lane cases also preserved the
golden output and identified the corrupted lane using mismatch outputs.

## 5. Multiple-Lane Fault Characterization

All 100 two-lane cases passed the internal consistency checks for:
- Bitwise majority equation
- Global mismatch indication
- Individual lane mismatch indications

No guarantee of correct golden output is claimed for two-lane corruption.

## 6. Common-Mode Fault Characterization

All 8 common-mode cases behaved as expected.

Identical XOR masks applied to all replicas resulted in:
- Identical corrupted replica outputs
- A correspondingly corrupted voted output
- No mismatch indication

This demonstrates a common-mode limitation of the implemented TMR
architecture.

## 7. Final Result

DAY 3 CAMPAIGN: PASS

- Campaign cases: 1076
- Passed cases: 1076
- Failed cases: 0

## 8. Limitations

This campaign injects faults at replica outputs using XOR masks.

It does not establish:
- Radiation tolerance
- Physical independence of replica implementations
- Protection against voter faults
- Internal register or pipeline transient fault tolerance
- Clock or power fault tolerance
- FPGA or ASIC hardware qualification

The two-lane and common-mode tests characterize expected limitations;
they do not demonstrate fault recovery in those scenarios.

## 9. Evidence Files

- sim/logs/day3/compile.log
- sim/logs/day3/fault_campaign.log
- sim/waveforms/tmr_fault_campaign.vcd
- sim/tb/day3/tb_tmr_fault_campaign.vvp
