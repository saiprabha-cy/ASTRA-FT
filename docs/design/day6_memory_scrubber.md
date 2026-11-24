# ASTRA-FT Day 6 — Memory Scrubber

## Objective

Periodically scan ECC-protected memory and repair
correctable single-bit errors through writeback.

## FSM

- IDLE
- SCAN
- DONE

## Scrub Process

1. Start scan.
2. Select memory address.
3. Read stored codeword.
4. Decode SECDED.
5. Correct single-bit errors.
6. Re-encode corrected payload.
7. Write repaired codeword.
8. Count uncorrectable errors.
9. Advance to next address.
10. Complete full memory pass.

## Counters

- Words scanned
- Corrected errors
- Uncorrectable errors

## Verification

- Initialize all 16 memory locations.
- Inject a single-bit error into one location.
- Inject a double-bit error into another location.
- Scrub the full memory.
- Verify correction writeback.
- Verify double-bit corruption remains invalid.
- Verify unaffected data.

## Limitations

- Manual start input
- Single-pass scrub
- No timer-based periodic trigger
- No scrub scheduling priority analysis
- No recovery of uncorrectable data
- No scrubbing during physical SRAM timing constraints
- No radiation testing

## Conclusion

The scrubber performs a complete scan of the protected
memory and repairs correctable corruption while recording
uncorrectable errors.
