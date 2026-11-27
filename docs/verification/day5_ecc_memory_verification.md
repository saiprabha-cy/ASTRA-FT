# ASTRA-FT Day 5 — ECC Memory Verification

## 1. Objective

Verify the SECDED-protected memory subsystem using the existing
32-bit payload and 39-bit encoded codeword architecture.

The verification exercises normal memory operation, error correction,
error detection, scrubber codeword access, and storage write arbitration.

## 2. Design under test

RTL:
- rtl/memory/ecc_memory_32.sv
- rtl/ecc/secded_encoder_32.sv
- rtl/ecc/secded_decoder_32.sv

Memory configuration:
- Depth: 16 words
- Address width: 4 bits
- Payload width: 32 bits
- Stored ECC codeword width: 39 bits

The memory array is not initialized by reset in the current RTL.
The testbench initializes all 16 addresses through normal writes before
performing clean read verification.

## 3. Verification campaign

| Test | Expected cases |
|---|---:|
| Clean reads across all memory addresses | 16 |
| Single-bit correction positions | 39 |
| Distinct double-bit error combinations | 741 |
| Storage arbitration cases | 2 |
| Scrubber raw codeword interface assertions | 1 |
| Total assertions | 799 |

### Single-bit campaign

Each of the 39 encoded codeword bit positions is independently
corrupted using the memory fault-injection interface.

Expected behavior:
- Corrected payload equals the original payload.
- read_data_valid is asserted.
- read_error_detected is asserted.
- read_error_corrected is asserted.
- read_uncorrectable_error is deasserted.

### Double-bit campaign

All distinct pairs of the 39 encoded codeword positions are tested.

Number of pairs:

C(39,2) = 741

Expected behavior:
- read_data_valid is deasserted.
- read_error_detected is asserted.
- read_error_corrected is deasserted.
- read_uncorrectable_error is asserted.

The testbench does not treat read_data as valid for an uncorrectable
codeword.

### Storage arbitration

The memory RTL implements this priority:

1. User write.
2. Scrubber writeback.
3. Fault injection.

The testbench checks:
- User write wins when all three controls are asserted.
- Scrubber write wins over fault injection.

### Scrubber read interface

The testbench checks that the scrubber read port exposes the stored
39-bit codeword at the selected address.

## 4. Evidence

New campaign:
- sim/logs/day5/full_compile.log
- sim/logs/day5/full_campaign.log
- sim/tb/day5/tb_day5_ecc_memory_full.vvp
- sim/waveforms/day5_ecc_memory_full.vcd

Original regression:
- sim/logs/day5_memory.log

## 5. Result

Fill this section only after inspecting the actual simulator logs.

Required passing conditions:
- All 16 clean reads pass.
- All 39 single-bit correction cases pass.
- All 741 double-bit detection cases pass.
- Both arbitration cases pass.
- Scrubber raw codeword interface assertion passes.
- Total assertions: 799.
- Failed assertions: 0.
- New campaign status: DAY 5 ECC MEMORY STATUS: PASS.
- Original Day 5 regression also passes.

## 6. Limitations

This is RTL simulation-based verification.

It does not establish:
- Exhaustive formal correctness of the complete memory subsystem.
- Radiation or single-event-effect qualification.
- Physical SRAM or FPGA block-memory behavior.
- Timing closure, placement, routing, or power integrity.
- Correct operation under arbitrary simultaneous read/write timing
  beyond the cases explicitly tested.
- Detection of every possible three-bit or higher-order error pattern.

The memory fault injection interface is a simulation mechanism.
It does not model the physical characteristics of radiation-induced
memory faults.

## 7. Conclusion

The Day 5 ECC memory verification result must be based on the actual
new campaign and original regression logs. Do not mark this task as
passed if any required check fails or the evidence is incomplete.
