# ASTRA-FT Day 11
# ASIC RTL-to-GDS Exploration

## 1. Objective

Explore the ASIC implementation process using an
open-source RTL-to-GDS flow.

## 2. Design

Top module:
astra_ft_system

RTL architecture:
- Triple Modular Redundancy
- Majority voter
- SECDED encoder and decoder
- ECC protected memory
- ECC scrubber
- Watchdog and recovery FSM

## 3. Tools

- OpenLane 2
- Yosys
- OpenROAD
- SkyWater SKY130
- SKY130 HD standard-cell library
- Magic
- KLayout
- Netgen

## 4. Flow Configuration

| Parameter | Value |
|-----------|-------|
| Top module | astra_ft_system |
| PDK | sky130A |
| Standard-cell library | sky130_fd_sc_hd |
| Clock port | |
| Clock period | |
| Initial core utilization | |
| Placement density target | |

## 5. RTL Synthesis

| Metric | Result |
|--------|--------|
| Synthesis completed | |
| Standard cell count | |
| Estimated area | |
| Sequential cells | |
| Combinational cells | |

## 6. Floorplan

| Metric | Result |
|--------|--------|
| Floorplan completed | |
| Core area | |
| Die area | |
| Utilization | |

## 7. Placement

| Metric | Result |
|--------|--------|
| Placement completed | |
| Placement violations | |
| Congestion observations | |

## 8. Clock Tree Synthesis

| Metric | Result |
|--------|--------|
| CTS completed | |
| Clock tree generated | |
| Clock-related warnings | |

## 9. Routing

| Metric | Result |
|--------|--------|
| Global routing completed | |
| Detailed routing completed | |
| Routing violations | |
| Congestion | |

## 10. Timing Analysis

| Metric | Result |
|--------|--------|
| Clock constraint | |
| Worst setup slack | |
| Total negative slack | |
| Critical path | |
| Timing analysis stage | |

## 11. Physical Outputs

- [ ] Final GDS generated
- [ ] Final DEF generated
- [ ] Final netlist generated
- [ ] Final LEF generated
- [ ] Timing reports generated
- [ ] Area reports generated

## 12. Limitations

- No fabrication
- No silicon measurements
- No radiation qualification
- No physical fault-injection campaign
- PDK is used for educational open-source exploration
- Results are not foundry signoff
- Results are not aerospace hardware qualification

## 13. Conclusion

Summarize what the ASIC flow demonstrated and
identify the stages that successfully completed.
