# Phase 18 ROB / In-Order Commit Experiment

## Summary

Phase 18 adds a constrained reorder-buffer experiment beside the standalone Tomasulo-style scheduler. The goal is to separate out-of-order issue/execution/broadcast from in-order architectural commit.

This is not a full out-of-order CPU. It is a small open-source-tool-compatible SystemVerilog model that demonstrates why a ROB is needed after reservation stations and CDB-style wakeup exist.

## Files

- `rtl/tomasulo_rob_experiment_core.sv`: standalone ROB + reservation-station experiment.
- `rtl/tomasulo_alu_model.sv`: reused ALU model for ADD/SUB/AND/OR/XOR/ADDI.
- `tb/tb_tomasulo_rob.sv`: self-checking ROB validation suite.
- `scripts/run_rob_tests.ps1`: simulation and report runner.
- `scripts/summarize_rob_reports.py`: parses `ROBPERF:` into Markdown/CSV.
- `scripts/run_rob_lint.ps1`: focused Verilator lint.
- `scripts/run_rob_synth.ps1`: focused Yosys sanity synthesis.
- `synth/synth_rob.ys`: Yosys script for the ROB experiment.

## Model Structure

The experiment keeps a small reservation-station array and adds a 4-entry circular ROB. Dispatch allocates both an RS entry and a ROB entry. The destination producer tag is the ROB index.

```text
instruction/uop
  -> dispatch
  -> allocate ROB entry
  -> allocate RS entry
  -> issue ready RS entry to ALU
  -> CDB broadcast writes completed value into ROB
  -> ROB head commits in program order
```

The ROB entry tracks:

- valid bit
- ready/completed bit
- thread ID
- destination architectural register
- destination-valid bit
- result value
- sequence ID

The register-status table now points to ROB tags:

```text
reg_busy[thread][rd]
reg_tag[thread][rd] = producer ROB tag
```

## Completion Versus Commit

Broadcast completion and architectural commit are intentionally separated.

When the ALU finishes, the result is broadcast on a CDB-style path. That broadcast:

- wakes matching RS source operands
- writes the result into the matching ROB entry
- marks the ROB entry ready

It does not directly update the architectural register file.

Architectural state updates only when the ROB head is valid and ready:

```text
if ROB head ready:
  commit head entry
  update architectural register if rd != x0
  clear register-status only if the committed tag still owns rd
else:
  stall commit
```

A younger completed instruction must wait if an older ROB head is not ready.

## Supported Operations

The ROB experiment supports:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI

Memory operations and branches are intentionally unsupported. Real OOO memory requires a load/store queue and memory disambiguation. Real branch support requires speculation, checkpoints, and recovery.

## Stale Tag Protection

On commit, the register-status table is cleared only if the committed ROB tag still matches the current owner tag for that architectural register. This prevents an older producer from clearing a newer producer's mapping.

The testbench includes a same-destination sequence where a newer producer replaces an older register-status tag. The older commit is allowed to update architectural state in order, but it cannot clear the newer producer tag.

## Thread-Aware Behavior

The experiment keeps two thread contexts for continuity with earlier SMT-style work:

- register file state is per thread
- register-status tags are per thread
- ROB entries carry `tid`
- CDB wakeup checks thread ID
- commit updates only the entry's thread context

This is still a simplified experiment, not full SMT out-of-order execution.

## Verification

Focused ROB validation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_tests.ps1 -SkipPriorRegressions
```

Full ROB flow with prior Tomasulo/scoreboard regression reference:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_tests.ps1
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_synth.ps1
```

Generated artifacts:

- `reports/perf/rob_summary.md`
- `reports/perf/rob_summary.csv`
- `reports/perf/rob_logs/rob_validation.log`
- `reports/sim/rob_trace.log`
- `sim/phase18_rob.vcd`
- `reports/lint_rob.log`
- `reports/synth_rob.log`

The validation suite performs 56 explicit checks and fails if fewer than 20 meaningful checks run.

## Key Validated Behaviors

The directed suite validates:

- ROB allocation and reuse
- ROB full stall detection
- register-status mapping to ROB tags
- source waiting on ROB tags
- CDB completion into ROB entries
- wakeup through matching ROB tags
- architectural register update only at commit
- x0 commit suppression
- stale tag clear protection
- younger completed instruction waiting behind older not-ready head
- head-not-ready commit stalls
- ADD/SUB/AND/OR/XOR/ADDI committed results
- thread-aware register independence
- report and counter consistency

## Design Explanation

The strongest way to explain this phase is:

> Phase 17 showed reservation stations and CDB wakeup. Phase 18 adds a ROB so completion is no longer the same thing as commit. A younger instruction can execute and broadcast early, but its result waits in the ROB until all older instructions retire. That is the basic mechanism that lets an out-of-order backend preserve in-order architectural state.

Key distinction:

```text
CDB broadcast = result is available internally.
ROB commit    = result becomes architectural state.
```

A ROB matters because exceptions, branch mispredictions, and stores require precise architectural recovery. This phase does not implement those full recovery mechanisms, but it demonstrates the retirement structure they depend on.

## Limitations

This phase does not implement:

- full physical register renaming
- free list
- ROB-based precise exceptions
- branch speculation or rollback
- load/store queue
- memory disambiguation
- speculative stores
- multiple functional units
- multiple CDB arbitration
- production out-of-order issue/select logic

## Recommended Phase 19

Phase 19 should add a limited load/store queue preparation experiment:

- model memory uops separately from ALU uops
- add load/store queue entries
- keep memory ordering conservative
- demonstrate why memory disambiguation is needed
- do not implement full speculative memory execution yet

