# ASTRA-FT Day 3 — Fault Injection Campaign

## Objective

Systematically evaluate the Triple Modular Redundancy (TMR)
subsystem under injected output faults.

## Architecture Under Test

- Three replicated processing lanes
- Bitwise majority voter
- Output XOR fault injection masks
- Global mismatch detection
- Individual lane mismatch indicators

## Test Campaign

### 1. Exhaustive Single-Bit Fault Injection

Test all output bit positions in all three replicas across
all eight supported operations.

Number of tests:

8 operations × 32 bits × 3 lanes = 768 tests

Expected behavior:
- Two healthy lanes provide the correct result.
- Majority voting reconstructs the correct output.
- Fault disagreement is detected.

### 2. Random Single-Lane Multi-Bit Fault Injection

200 randomized tests.

One replica is corrupted using a randomized nonzero
32-bit fault mask.

Expected behavior:
- The remaining two replicas agree.
- The majority voter returns the correct result.
- Mismatch detection is asserted.

### 3. Simultaneous Two-Lane Faults

100 randomized characterization tests.

Expected behavior:
- Recovery is not guaranteed.
- The majority may follow the two faulty replicas.
- Results are recorded to characterize the architecture.

### 4. Common-Mode Faults

Eight operation scenarios.

The same nonzero corruption mask is applied to all
three replicas.

Expected behavior:
- All replicas agree on the corrupted result.
- The voter cannot identify the error.
- The mismatch detector remains inactive.

## Expected Test Counts

| Campaign | Tests |
|---|---:|
| Exhaustive single-bit | 768 |
| Random single-lane | 200 |
| Two-lane characterization | 100 |
| Common-mode | 8 |
| Total | 1,076 |

## Verification Criteria

- Single-bit fault recovery: PASS
- Random single-lane recovery: PASS
- No unknown outputs in tested cases: PASS
- Two-lane fault behavior characterized: PASS
- Common-mode vulnerability demonstrated: PASS
- No unexplained test failures

## Limitations

This campaign models faults as XOR corruption of the
replica outputs.

It does not model:
- Radiation particle transport
- Single-event transients at transistor level
- Timing faults or metastability
- Clock or reset common-mode failures
- Power supply disturbances
- Faults inside the voter
- Physical FPGA routing or placement vulnerabilities

The results demonstrate architectural behavior under the
defined fault model, not radiation qualification.

## Conclusion

The TMR subsystem is expected to recover from a single
replica fault because two healthy replicas maintain
agreement.

With two faulty replicas, the voter may produce an
incorrect result.

When all replicas experience identical corruption,
disagreement detection cannot detect the common-mode error.

This demonstrates both the value and limitations of TMR
for fault-tolerant spacecraft digital architectures.
