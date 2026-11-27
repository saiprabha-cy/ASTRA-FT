# ASTRA-FT Day 4 — Full SECDED Verification Report

## 1. Objective

Verify the existing 32-bit SECDED encoder and decoder using
deterministic payload patterns and injected codeword errors.

The verification checks:

- Clean codeword decoding
- Single-bit error correction
- Double-bit error detection
- Syndrome values
- Decoder status flags
- Encoder Hamming parity equations
- Payload-bit placement
- Overall even parity

## 2. Architecture

| Property | Value |
|---|---:|
| Payload width | 32 bits |
| Hamming parity bits | 6 |
| Overall parity bits | 1 |
| Encoded codeword width | 39 bits |
| Hamming positions | 1 through 38 |
| Overall parity encoded bit | 38 |
| Hamming parity positions | 1, 2, 4, 8, 16, 32 |

The six Hamming parity positions are excluded from the
32-bit payload positions.

## 3. Verification Environment

- Simulator: Icarus Verilog
- Testbench: tb/day4/tb_day4_secded_full.sv
- Encoder: rtl/ecc/secded_encoder_32.sv
- Decoder: rtl/ecc/secded_decoder_32.sv
- Runner: scripts/run_day4_secded.sh

The existing unit testbench is retained and run separately.

## 4. Payload Patterns

80 deterministic payload patterns are used:

- All-zero pattern
- All-one pattern
- Alternating-bit patterns
- Fixed hexadecimal patterns
- Walking-one patterns
- Walking-zero patterns
- Deterministic mixed patterns

## 5. Test Coverage

For every payload pattern:

1. One clean codeword is checked.
2. All 39 single-bit error positions are injected.
3. All 741 distinct double-bit error pairs are injected.

The encoder structure is also checked once per payload pattern.

### Expected case counts

| Category | Calculation | Cases |
|---|---:|---:|
| Clean | 80 × 1 | 80 |
| Single-bit | 80 × 39 | 3,120 |
| Double-bit | 80 × C(39,2) | 59,280 |
| Total decoder cases | 80 × 781 | 62,480 |
| Encoder structure checks | 80 × 1 | 80 |

## 6. Expected SECDED Behavior

| Syndrome | Overall parity | Expected classification |
|---|---|---|
| Zero | Zero | No error |
| Nonzero | One | Correct a valid Hamming bit |
| Zero | One | Overall parity bit error |
| Nonzero | Zero | Detect an even-parity multi-bit error |

For the tested single-bit errors:

- The decoder must assert error_detected.
- The decoder must assert error_corrected.
- The decoder must not assert uncorrectable_error.
- The corrected payload must match the original payload.
- The syndrome must identify the injected Hamming position.
- An overall parity-bit error must have a zero Hamming syndrome.

For the tested double-bit errors:

- The decoder must assert error_detected.
- The decoder must not assert error_corrected.
- The decoder must assert uncorrectable_error.
- The syndrome must match the independently calculated XOR
  of the two affected Hamming positions.

## 7. Evidence Files

Expanded campaign:

- sim/logs/day4/compile.log
- sim/logs/day4/full_campaign.log
- sim/tb/day4/tb_day4_secded_full.vvp
- sim/waveforms/day4_secded_full.vcd

Original unit regression:

- sim/logs/day4/baseline_compile.log
- sim/logs/day4/baseline_unit.log
- sim/tb/day4/tb_secded_32_baseline.vvp

## 8. Limitations

This verification is simulation-based.

It does not establish:

- Formal proof over every possible input and state
- Radiation tolerance or radiation qualification
- Physical SRAM behavior
- Multi-bit upset spatial or temporal characteristics
- Protection against every possible three-bit or higher-order error
- Timing closure
- FPGA or ASIC implementation correctness
- Physical placement and routing
- Power or clock fault tolerance

SECDED guarantees are limited to the code's single-error correction
and double-error detection model. Some error patterns involving
three or more flipped bits may be miscorrected or misclassified.

When uncorrectable_error is asserted, corrected_data must not be
treated as valid application data.

## 9. Result

The result must be filled from the actual simulator logs.

Do not mark this report PASS unless:

- The original unit regression reports SECDED STATUS: PASS.
- The expanded campaign reports DAY 4 SECDED STATUS: PASS.
- All expected case counts match.
- All failure counts are zero.

