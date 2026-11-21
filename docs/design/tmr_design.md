# ASTRA-FT — Day 2 TMR Design

## Objective

Implement three replicated command-processing cores
with majority voting and controlled fault injection.

## Replica Core

Each replica implements the same combinational
32-bit command-processing datapath.

Supported operations:

- ADD
- XOR
- AND
- OR
- Rotate-left
- Equality comparison
- Pass A
- Pass B

## TMR Architecture

Three identical replicas operate in parallel.

Their outputs are passed through a bitwise
majority voter.

## Fault Injection

Faults are injected through XOR masks at
each replica output.

This emulates selected digital corruption.

## Mismatch Monitoring

The subsystem detects disagreement between
the replicas.

Each replica is compared against the voted
output to generate lane mismatch indicators.

## Verification

Directed test cases include:

- All eight operations
- Addition wraparound
- Rotate-left by zero
- Rotate-left by one
- Single-lane faults
- Multiple-lane faults
- Majority masking limitation

## Limitations

The current processing core is combinational.

The fault masks emulate digital corruption.

No physical radiation testing is performed.