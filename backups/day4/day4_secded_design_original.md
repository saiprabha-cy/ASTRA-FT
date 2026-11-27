# ASTRA-FT Day 4 — SECDED ECC

## Objective

Implement a 32-bit SECDED encoder and decoder using
extended Hamming coding.

## Architecture

- Payload: 32 bits
- Hamming parity bits: 6
- Overall parity bit: 1
- Encoded word: 39 bits

## Hamming Parity Locations

Positions 1, 2, 4, 8, 16 and 32 contain parity bits.

The remaining positions in the 38-bit Hamming codeword
contain payload bits.

The 39th encoded bit is the overall parity bit.

## Encoder

1. Place payload bits into non-parity positions.
2. Calculate six even-parity bits.
3. Map the 38-bit Hamming codeword.
4. Calculate overall parity.
5. Produce the 39-bit encoded word.

## Decoder

1. Recover the 38-bit Hamming codeword.
2. Calculate six parity-check results.
3. Construct the six-bit syndrome.
4. Calculate overall parity.
5. Classify the error.
6. Correct valid single-bit errors.
7. Extract corrected payload.

## SECDED Decision Logic

| Syndrome | Overall parity | Action |
|---|---|---|
| 0 | 0 | No error |
| Nonzero | 1 | Correct valid Hamming bit |
| 0 | 1 | Overall parity bit error |
| Nonzero | 0 | Detect double-bit error |

## Verification

- 5 clean payload tests
- 195 single-bit fault tests
- 741 double-bit fault tests
- 941 total tests

## Expected Results

- All clean words decoded correctly.
- All single-bit faults corrected.
- All double-bit faults detected.
- Double-bit faults are not corrected.
- Overall parity bit errors do not corrupt the payload.

## Limitations

This implementation demonstrates combinational SECDED
logic and fault injection.

It does not model:
- Memory arrays or physical SRAM behavior
- Radiation transport
- Multi-bit upset clustering in physical memory
- Timing closure
- Memory read/write arbitration
- Scrubbing
- System-level recovery
- FPGA physical placement

The decoder output must not be used as valid data when
uncorrectable_error is asserted.

## Conclusion

The SECDED architecture provides single-bit correction
and double-bit error detection for the tested 39-bit
codeword model.
