# Phase 6: Branch Prediction Baseline

Phase 6 adds a simple conditional-branch prediction baseline to the 5-stage pipelined RV32I core.

## Predictor Type

The implemented predictor is a 1-bit PC-indexed table in `rtl/branch_predictor.sv`.

- Table entries: 16
- Index: `PC[5:2]`
- Reset state: not taken
- Update point: branch resolution in EX
- A table entry is updated to the actual resolved branch direction

This is intentionally simpler than gshare. It creates the fetch, update, counter, trace, and reporting infrastructure needed before trying a global-history predictor.

## Instructions Affected

Prediction is applied to conditional branches:

- BEQ
- BNE

JAL and JALR remain EX-resolved redirects. JAL is unconditional, and JALR is indirect, so they are not predicted in this phase.

## Fetch Behavior

When IF fetches an instruction whose opcode is a conditional branch, the predictor table is consulted.

- If predicted not taken, fetch continues at `PC + 4`.
- If predicted taken, IF computes the B-type immediate target and fetch redirects to that target.

If an instruction is not a conditional branch, the predictor output is ignored and fetch continues normally.

## Resolve and Flush Behavior

Branches resolve in EX. The pipeline compares:

- predicted direction vs. actual direction
- predicted target vs. actual target, when predicted taken

On a correct prediction, the pipeline continues normally. On a misprediction, younger wrong-path instructions are flushed and the PC redirects to the correct target.

Wrong-path instructions are prevented from committing architectural state by the existing valid-bit flush path.

## Counters

The pipelined core exposes these branch prediction counters:

- total conditional branches resolved
- predicted taken count
- predicted not-taken count
- actual taken count
- actual not-taken count
- correct prediction count
- misprediction count

The Phase 6 directed test writes the summary to:

```text
reports/sim/branch_prediction_report.log
```

## Trace

The Phase 6 directed test also writes a human-readable trace:

```text
reports/sim/branch_prediction_trace.log
```

Each cycle includes IF/ID/EX/MEM/WB state plus a branch prediction line:

```text
BP: pred_taken=... pred_target=... actual_taken=... actual_target=... mispredict=...
```

The VCD waveform is:

```text
sim/phase6_branch_predictor.vcd
```

## How to Run

Run the full Phase 6 branch predictor flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1
```

Run only the Phase 6 directed branch-predictor test:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1 -SkipRegression
```

Optional checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase6_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase6_synth.ps1
```

## Current Limitations

- This is not gshare.
- There is no global branch history register yet.
- There is no 2-bit saturating counter yet.
- JALR is not predicted.
- Randomized tests still focus on deterministic architectural correctness, not branch prediction accuracy.
- The pipeline remains a simple teaching baseline; advanced features such as SMT, out-of-order execution, caches, CSR, exceptions, and interrupts are still excluded.


