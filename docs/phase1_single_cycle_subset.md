# Phase 1 Single-Cycle RV32I Subset

Phase 1 implements a small single-cycle CPU supporting only:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI

The PC resets to zero and increments by four every cycle. There is no branch, jump, load, store, CSR, exception, interrupt, or pipeline behavior.

## Datapath

Instruction memory feeds the decoder. The decoder selects source registers, immediate value, ALU operation, and register write enable. The ALU result writes back to the register file. Register x0 is hardwired to zero.

## Test

`tests\phase1_basic.hex` is loaded into instruction memory. The testbench runs enough cycles for the program and checks final register values.
