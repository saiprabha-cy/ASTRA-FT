# ASTRA-FT
## Fault-Tolerant Digital System for Aerospace Applications

ASTRA-FT is an RTL-based fault-tolerant digital system designed to explore hardware redundancy, fault detection, error correction, memory integrity, autonomous recovery, FPGA mapping, and ASIC physical implementation.

The project is developed and verified using open-source simulation, synthesis, and physical-design tools.

### Architecture

- Triple Modular Redundancy (TMR)
- Majority voter
- Fault injection and mismatch detection
- 32-bit SECDED error correction
- ECC-protected memory
- Memory scrubbing
- Watchdog and recovery FSM
- Safe-mode transition logic

### Verification

- Unit-level RTL testbenches
- Integrated system regression
- Exhaustive and randomized fault campaigns
- Single-lane and multiple-lane fault experiments
- ECC correction and uncorrectable-error detection
- Recovery and safe-mode validation

### FPGA Implementation

- Yosys generic synthesis
- ECP5 architecture mapping
- LUT, FF, carry-chain and mux resource analysis
- Synthesis architecture comparison experiments

### ASIC Implementation

- OpenLane
- Yosys
- OpenROAD
- SKY130 standard-cell library
- Floorplanning
- Placement
- Clock-tree synthesis
- Routing
- DRC and LVS
- GDS generation

### Tools

SystemVerilog, Icarus Verilog, GTKWave, Verilator, Yosys, OpenLane, OpenROAD, KLayout, Magic, Netgen, Python, Bash.

### Verification Results

- 1,076 fault campaign tests
- 15 integrated system tests
- Functional simulation verified
- FPGA synthesis and mapping completed
- ASIC physical-design flow completed
- GDS generated
- DRC passed
- LVS passed

### Limitations

ASTRA-FT is a simulation and open-source implementation-flow project. It has not been fabricated, physically validated on an FPGA board, or radiation-qualified.

The ASIC flow reported antenna violations and maximum-slew warnings. These limitations are documented rather than presented as signoff results.

### Project Status

Completed core implementation and verification, FPGA synthesis analysis, and educational ASIC RTL-to-GDS exploration. Future work includes formal verification, physical FPGA validation, improved physical-design checks, and fault-tolerance architecture optimization.