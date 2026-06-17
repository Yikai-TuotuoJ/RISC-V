# Phase 2 Single-Cycle Memory and Branch Support

Phase 2 extends the existing single-cycle RV32I subset with exactly these instructions:

- LW
- SW
- BEQ
- BNE

The CPU remains single-cycle. There is no pipeline, flush, forwarding, hazard detection, branch prediction, CSR, exception, interrupt, cache, or formal flow in this phase.

## Preserved Phase 1 Instructions

The original Phase 1 instructions remain supported:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI

## Memory Behavior

`LW` and `SW` compute the byte address as `rs1 + sign_extended_immediate`.

The data memory is a simple word-addressed simulation memory. Address bits `[9:2]` select a 32-bit word. Phase 2 assumes word-aligned accesses and intentionally ignores misaligned access exceptions.

- `SW rs2, imm(rs1)` writes `rs2` to data memory on the clock edge.
- `LW rd, imm(rs1)` reads data memory combinationally and writes the loaded word to `rd` on the clock edge.

## Branch Behavior

`BEQ` and `BNE` use the standard RV32I B-type immediate encoding.

- Taken branch: `pc_next = pc + sign_extended_branch_immediate`
- Not taken branch: `pc_next = pc + 4`

Because the CPU is still single-cycle, there is no branch flush behavior yet.

## Immediate Generation

The decoder now generates the selected immediate for each supported instruction class:

- I-type for `ADDI` and `LW`
- S-type for `SW`
- B-type for `BEQ` and `BNE`

Unsupported opcodes or unsupported funct3/funct7 combinations set `illegal_instr`.

## Directed Test

`tests\phase2_mem_branch.hex` verifies:

- Existing ALU behavior still works.
- `SW` writes a word to data memory.
- `LW` reads the word back.
- `BEQ` taken and not-taken paths.
- `BNE` taken and not-taken paths.
- `x0` remains hardwired to zero.

Run:

```powershell
.\scripts\run_phase2_sim.ps1
.\scripts\run_phase2_wave.ps1
.\scripts\run_lint.ps1
.\scripts\run_synth.ps1
```
