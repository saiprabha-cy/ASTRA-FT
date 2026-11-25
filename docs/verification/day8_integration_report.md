
# ASTRA-FT Day 8 — System Integration Report

## Objective

Integrate TMR processing, ECC memory, memory scrubber,
watchdog recovery and safe-mode monitoring.

## Integrated Modules

- replica_core
- majority_voter
- astra_tmr_subsystem
- secded_encoder_32
- secded_decoder_32
- ecc_memory_32
- ecc_scrubber_32
- watchdog_recovery_fsm
- astra_ft_system

## Verification Environment

- Icarus Verilog:
- Verilator:
- GTKWave:
- Ubuntu / WSL:

## Test Results

| Test | Result |
|---|---|
| Startup/reset | |
| TMR normal operation | |
| TMR single-lane fault | |
| TMR mismatch identification | |
| TMR result memory write/read | |
| ECC single-bit correction | |
| Scrubber correction | |
| Corrected word clean readback | |
| Double-bit rejection | |
| Scrubber uncorrectable count | |
| Watchdog heartbeat | |
| Watchdog timeout/recovery | |
| Recovery success | |
| Safe mode | |

## Results

- Tests:
- Passed:
- Failed:

## Waveform Inspection

Describe inspected signal behavior.

## Known Limitations

- Simulation-only fault injection
- No physical radiation testing
- No actual processor core reset implementation
- Safe mode is a status/control output
- No clock-domain crossing protection
- No physical memory implementation
- Scrubber is not pausable during concurrent user writes
- Uninitialized memory must be initialized in simulation

## Conclusion

State only the conclusions supported by actual test output.
