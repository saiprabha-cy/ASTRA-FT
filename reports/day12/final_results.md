# ASTRA-FT Final Results

## 1. Functional Verification

| Test | Result |
|------|--------|
| Majority voter | PASS |
| TMR subsystem | PASS |
| Fault campaign | PASS |
| SECDED | PASS |
| ECC memory | PASS |
| ECC scrubber | PASS |
| Watchdog recovery FSM | PASS |
| Integrated regression | PASS |

## 2. Fault Campaign

| Fault category | Tests | Result |
|----------------|------:|--------|
| Exhaustive single-bit | 768 | PASS |
| Randomized single-lane multibit | 200 | PASS |
| Double-lane faults | 100 | PASS |
| Common-mode faults | 8 | Expected undetected |
| Total | 1076 | PASS |

## 3. Generic Synthesis

| Module | Cells |
|--------|------:|
| Replica core | 1125 |
| TMR subsystem | 4139 |
| ECC memory | 3430 |
| ECC scrubber | 1184 |
| Watchdog recovery FSM | 514 |
| ASTRA-FT top | 9299 |

## 4. ECP5 Mapping

| Resource | Count |
|----------|------:|
| LUT4 | 2340 |
| PFUMX | 759 |
| L6MUX21 | 391 |
| CCU2C | 166 |
| TRELLIS_FF | 224 |
| TRELLIS_DPR16X4 | 30 |
| Total | 3928 |

## 5. FPGA Mapping Experiments

| Experiment | Total Cells |
|------------|------------:|
| Baseline | 3928 |
| No CCU2 | 3741 |
| No DFFE | 3904 |
| No BRAM | 3928 |
| No DSP | 3382 |

## 6. ASIC Flow

| Stage | Status |
|-------|--------|
| RTL synthesis | Completed |
| Floorplan | Completed |
| Placement | Completed |
| Clock tree synthesis | Completed |
| Routing | Completed |
| Final GDS generation | Completed |
| DRC | PASS |
| LVS | PASS |
| Setup check | No violations reported |
| Hold check | No violations reported |
| Antenna | FAIL - violations reported |
| Maximum slew | Warnings reported |

## 7. Physical Outputs

- GDS generated
- Final netlist generated
- DEF generated
- Layout inspected in KLayout

## 8. Limitations

- No FPGA board implementation
- No FPGA bitstream/hardware validation
- No silicon fabrication
- No radiation testing
- No radiation qualification
- ASIC antenna violations remain
- Maximum slew warnings remain
- Physical design is an educational open-source flow

## 9. Conclusion

ASTRA-FT successfully demonstrated simulation-based verification,
fault injection, FPGA architecture mapping, and an open-source
ASIC RTL-to-GDS implementation flow.
