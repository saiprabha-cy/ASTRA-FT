# ASTRA-FT Day 5 — ECC-Protected Memory

## Objective

Implement a 32-bit protected memory architecture using
the SECDED encoder and decoder developed on Day 4.

## Memory Configuration

- 32-bit payload
- 39-bit protected word
- 16 memory locations
- 4-bit address
- 624 storage bits in the simulation model

## Write Operation

Payload is encoded before it is written to memory.

## Read Operation

The stored codeword is decoded on read.

- Clean data: return data, valid=1
- Single-bit error: corrected data returned, valid=1
- Double-bit error: error flags asserted, valid=0

## Fault Injection

The simulation interface can XOR a specified mask into
a selected memory codeword.

## Verification

- Normal write/read
- Address independence
- Single-bit error correction
- Double-bit error detection
- Rewriting corrupted memory
- Correction at another bit position

## Limitations

- Behavioral memory model
- No physical SRAM
- No memory timing model
- No arbitration between multiple independent requesters
- No radiation qualification
- No system-level recovery policy
- No FPGA placement or timing validation yet

## Conclusion

The protected memory provides an ECC encoding path
for writes and ECC decoding/correction for reads.
Uncorrectable data is flagged and invalidated.
