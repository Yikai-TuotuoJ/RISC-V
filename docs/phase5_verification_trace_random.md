# Phase 5 Pipeline Verification

## Scope

Phase 5 improves verification and observability for the existing 5-stage pipeline. It does not add branch prediction, CSR, exceptions, interrupts, caches, out-of-order execution, SMT, Tomasulo, UCP, or formal verification.

## What Was Added

- Read-only pipeline debug outputs on `rv32i_pipeline_core`.
- Human-readable per-cycle trace log: `reports/sim/pipeline_trace.log`.
- CSV trace log: `reports/phase5_pipeline_trace.csv`.
- Directed trace testbench that checks redirects, writebacks, x0, jump/link behavior, memory, and final architectural state.
- Python random generator: `scripts/gen_random_pipeline_test.py`.
- Random pipeline testbench with expected register/memory comparison.
- Aggregate Windows runner: `scripts/run_pipeline_tests.ps1`.

## Trace Contents

Each cycle records:

- IF PC, instruction, valid
- ID PC, instruction, valid
- EX PC, instruction, valid
- MEM PC, instruction, valid
- WB PC, instruction, valid
- WB destination register
- WB write data
- WB write enable
- stall
- flush
- branch/jump taken redirect
- redirect target

The trace style is human-readable, for example:

```text
CYCLE=12
IF:  valid=1 pc=00000020 instr=00000013
ID:  valid=1 pc=0000001c instr=00000013
EX:  valid=1 pc=00000018 instr=00000013
MEM: valid=1 pc=00000014 instr=00000013
WB:  valid=1 pc=00000010 instr=01400113 rd=x2 we=1 wdata=00000014
CTRL: stall=0 flush=0 taken=0 target=00000024
```

## Commands

Run the full Phase 5 verification flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_pipeline_tests.ps1
```

Run individual checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase5_trace.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase5_random.ps1 -Seed 1 -Count 50
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase5_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase5_synth.ps1
```

Generate only the randomized program:

```powershell
E:\shixi02\tools\oss-cad-suite\lib\python3.exe .\scripts\gen_random_pipeline_test.py --seed 1 --count 50 --compat
```

## Randomized Test Subset

The randomized generator is conservative and hazard-free. It inserts NOPs because this pipeline does not yet implement forwarding or load-use stall logic.

Currently randomized instructions include:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI
- LUI
- AUIPC
- LW
- SW

Branches and jumps are covered by the directed pipeline test, not by the randomized generator yet.

## Important Limitation

The cleaner Phase 5 prompt requests directed tests for EX/MEM forwarding, MEM/WB forwarding, and load-use stalls. The current pipeline does not implement those mechanisms. I did not add failing tests that require unimplemented hardware, and I did not add the hazard unit in Phase 5 because this phase was scoped as verification and observability, not a CPU architecture feature phase.

Recommended follow-up before branch prediction: implement and verify forwarding plus load-use stall support, or explicitly accept this baseline pipeline as NOP-scheduled only.
