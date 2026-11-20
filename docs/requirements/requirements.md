
# ASTRA-FT — Engineering Requirements

## 1. Project Objective

Design and verify a radiation-aware fault-tolerant digital
architecture intended for spacecraft onboard computing.

The system will demonstrate hardware-level fault tolerance
through redundancy, error detection, correction and recovery.

## 2. Functional Requirements

FR-01: The system shall contain three processing replicas.

FR-02: The system shall implement a majority voting mechanism.

FR-03: The system shall detect disagreement between replicas.

FR-04: The system shall support controlled fault injection.

FR-05: The system shall implement single-error correction
and double-error detection using SECDED.

FR-06: The system shall contain an ECC-protected memory model.

FR-07: The system shall implement a memory scrubbing controller.

FR-08: The system shall implement fault monitoring.

FR-09: The system shall implement a watchdog mechanism.

FR-10: The system shall implement a recovery state machine.

FR-11: The system shall produce fault and recovery status.

## 3. Verification Requirements

VR-01: All RTL modules shall have self-checking testbenches.

VR-02: Testbenches shall include normal-operation tests.

VR-03: Fault injection shall be exercised in simulation.

VR-04: ECC shall be tested for single-bit and double-bit faults.

VR-05: Integration tests shall validate system behavior.

VR-06: Verification results shall be reproducible.

## 4. FPGA Requirements

FPGA-01: RTL shall be synthesizable where intended.

FPGA-02: Synthesis shall target an ECP5 architecture.

FPGA-03: Resource utilization shall be documented.

FPGA-04: Timing constraints shall be documented.

FPGA-05: FPGA implementation shall be attempted using
an open-source toolchain.

## 5. PCB Requirements

PCB-01: A custom FPGA carrier/interface board shall
be designed using KiCad.

PCB-02: The design shall include interface connectors,
debug signals and fault-injection facilities.

PCB-03: PCB fabrication outputs shall be generated
when the design is complete.

PCB-04: PCB design shall not imply physical
manufacture or hardware validation.

## 6. ASIC Extension Requirements

ASIC-01: The RTL shall be evaluated for ASIC synthesis.

ASIC-02: A documented open-source ASIC physical-design
flow shall be attempted.

ASIC-03: Area and timing reports shall be retained
when successfully generated.

ASIC-04: GDSII generation shall be attempted.

ASIC-05: Physical-design completion shall not imply
fabrication or silicon validation.

## 7. Limitations

This project is an educational engineering demonstrator.

It is not radiation-qualified.

Simulation does not prove radiation tolerance.

Fault injection does not reproduce all radiation effects.

No flight certification is claimed.
