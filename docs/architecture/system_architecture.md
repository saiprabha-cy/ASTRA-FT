
# ASTRA-FT System Architecture

## Overview

ASTRA-FT is a fault-tolerant digital architecture for
spacecraft computing demonstrations.

## Main Blocks

1. Input and command interface
2. Three processing replicas
3. Majority voter
4. Fault injection interface
5. Replica mismatch monitor
6. ECC encoder and decoder
7. Protected memory subsystem
8. Memory scrubbing controller
9. Watchdog
10. Recovery controller
11. System status and fault telemetry

## Processing Redundancy

Three logical replicas operate in parallel.

Their outputs are compared through majority voting.

A disagreement is detected and recorded.

The voting output is selected from the majority
of the three replica values.

## Fault Injection

Fault injection is controlled by simulation signals.

Injected faults emulate selected digital corruption.

They do not reproduce the physical behavior
of radiation interactions.

## Memory Protection

Memory words are encoded with SECDED.

Single-bit errors are corrected.

Double-bit errors are detected.

A memory scrubbing controller periodically
checks stored words.

## Recovery

The system monitors faults and selected
abnormal conditions.

A recovery controller handles defined
fault-management responses.

## FPGA Implementation

The RTL will be synthesized and mapped to
an ECP5 FPGA architecture.

## ASIC Extension

The RTL will be explored through synthesis
and physical design using an open-source
ASIC implementation flow.

## Project Limitations

The architecture is not radiation-qualified
and is not a flight-ready computer.
