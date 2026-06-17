# Phase 3 Jump and Upper-Immediate Support

Phase 3 extends the existing single-cycle RV32I subset with:

- JAL
- JALR
- LUI
- AUIPC

The CPU remains single-cycle. This phase does not add pipeline behavior, forwarding, hazard detection, branch prediction, CSR, exceptions, interrupts, caches, or formal verification.

## Preserved Instructions

Phase 1 and Phase 2 instructions remain supported:

- ADD, SUB, AND, OR, XOR, ADDI
- LW, SW
- BEQ, BNE

## Jump Behavior

`JAL rd, offset` writes `pc + 4` to `rd` and jumps to `pc + sign_extended_j_immediate`.

`JALR rd, imm(rs1)` writes `pc + 4` to `rd` and jumps to `(rs1 + sign_extended_i_immediate) & ~1`.

Writes to `x0` are ignored by the register file, so `JAL x0, offset` behaves as an unconditional jump without link storage.

## Upper-Immediate Behavior

`LUI rd, imm20` writes `{imm20, 12'b0}` to `rd`.

`AUIPC rd, imm20` writes `pc + {imm20, 12'b0}` to `rd`.

## Immediate Generation

The decoder now supports:

- I-type for `ADDI`, `LW`, and `JALR`
- S-type for `SW`
- B-type for `BEQ` and `BNE`
- U-type for `LUI` and `AUIPC`
- J-type for `JAL`

Unsupported opcodes or unsupported funct fields remain illegal.

## Directed Test

`tests\phase3_jump_upper.hex` verifies:

- LUI writes the expected upper-immediate value.
- AUIPC writes a PC-relative value.
- JAL writes a link and skips the following instruction.
- JALR writes a link and jumps through a register target.
- JAL with `rd=x0` jumps without changing `x0`.
- Existing x0 hardwiring remains intact.

Run:

```powershell
.\scripts\run_phase3_sim.ps1
.\scripts\run_phase3_wave.ps1
.\scripts\run_lint.ps1
.\scripts\run_synth.ps1
```
