# Phase 7: Gshare Branch Prediction

Phase 7 upgrades the pipelined CPU branch prediction infrastructure with a small gshare predictor while preserving the Phase 6 one-bit predictor as a selectable comparison mode.

## Predictor Configuration

The gshare predictor is implemented in `rtl/gshare_branch_predictor.sv`.

- PHT entries: 16
- GHR width: 4 bits
- Counter type: 2-bit saturating counter
- Initial counter state: weakly not taken
- PC index bits: `branch_pc[5:2]`
- Gshare index: `branch_pc[5:2] XOR GHR`

Prediction still applies only to conditional branches:

- BEQ
- BNE

JAL and JALR continue to use the existing EX-stage redirect path and are not predicted.

## Predictor Modes

`rv32i_pipeline_core` now has a `BP_MODE` parameter:

- `0`: no prediction / static not taken
- `1`: Phase 6 simple one-bit PC-indexed predictor
- `2`: Phase 7 gshare predictor

Older Phase 4 and Phase 5 tests use the default gshare mode but check architectural correctness only. The Phase 6 branch predictor test explicitly uses simple mode. The Phase 7 gshare test uses gshare mode and also instantiates a shadow simple-predictor core on the same program for comparison.

## Prediction and Update Timing

During IF, the core checks whether the fetched instruction is a conditional branch. If it is, the active predictor provides a taken/not-taken prediction.

- Predicted not taken: next PC is `PC + 4`.
- Predicted taken: next PC is the B-type branch target computed in IF.

The branch resolves in EX. At that point, the core:

- compares predicted direction and target against the actual result
- redirects the PC on misprediction
- flushes younger wrong-path instructions
- updates the active predictor using the actual branch outcome
- updates branch prediction counters

For gshare, the GHR shifts in the actual branch outcome at update time.

## Reports and Trace

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_gshare_tests.ps1
```

Generated artifacts:

- `reports/sim/gshare_branch_prediction_report.log`
- `reports/sim/gshare_branch_prediction_trace.log`
- `sim/phase7_gshare.vcd`

The trace includes gshare-specific fields:

```text
BP: mode=GSHARE pc=... ghr=... index=... pred_taken=... actual_taken=... mispredict=...
```

## Current Result

The first Phase 7 branch-heavy test is intentionally small and scheduled with NOPs. On this test, gshare is architecturally correct but less accurate than the simple one-bit predictor:

- Gshare: 27% accuracy, 3 correct out of 11
- Simple predictor on same program: 63% accuracy, 7 correct out of 11

This is a useful result, not a failure. Gshare can perform poorly on short streams with cold counters and aliasing. Later phases can add better branch-heavy benchmarks, larger tables, or different initialization policies before drawing broader conclusions.

## Limitations

- No return-address stack.
- No indirect predictor for JALR.
- No BTB beyond the current IF-computed branch target.
- No industrial-scale predictor features.
- Randomized tests still focus on architectural correctness, not predictor performance.
- The pipeline still uses scheduled tests until forwarding/hazard logic is added later.


