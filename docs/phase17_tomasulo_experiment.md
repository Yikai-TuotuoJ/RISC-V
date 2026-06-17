# Phase 17 Tomasulo-Style Dynamic Scheduling Experiment

## Summary

Phase 17 adds a standalone Tomasulo-style dynamic scheduling experiment beside the existing CPU cores. It builds on the Phase 16 scoreboard/readiness work and demonstrates the next concepts needed for out-of-order execution without converting the main RV32I pipeline into a full OOO processor.

The new model is intentionally separate from the proven single-cycle, pipelined, cache/UCP, SMT, and scoreboard paths. Existing cores remain the architectural reference and regression baseline.

## Files

- `rtl/tomasulo_alu_model.sv`: small combinational ALU for the experiment.
- `rtl/tomasulo_experiment_core.sv`: reservation-station, register-status, issue, execute, and CDB model.
- `tb/tb_tomasulo_experiment.sv`: directed self-checking validation suite.
- `scripts/run_tomasulo_tests.ps1`: simulation/report runner.
- `scripts/run_tomasulo_lint.ps1`: focused Verilator lint.
- `scripts/run_tomasulo_synth.ps1`: focused Yosys synthesis sanity.
- `scripts/summarize_tomasulo_reports.py`: parses `TOMPERF:` output into Markdown/CSV.
- `synth/synth_tomasulo.ys`: focused Yosys script.

## Model Structure

The experiment uses four reservation-station entries by default. Each entry records:

- valid bit
- issued bit
- thread ID
- operation
- destination architectural register
- source values
- source-ready bits
- source dependency tags
- destination tag
- sequence ID

The register-status table is a rename-lite structure:

```text
reg_busy[thread][arch_reg]
reg_tag[thread][arch_reg]
```

When an instruction is accepted, the destination register receives a new producer tag. Source operands either capture a value immediately or wait on a matching tag. Register `x0` is never marked busy and ignores writes.

## Supported Operations

The Phase 17 ALU subset is intentionally small:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI

Memory operations, branches, jumps, load/store queue behavior, and speculation are intentionally not part of this phase.

## Issue And Wakeup Behavior

The model selects one ready reservation-station entry for the ALU execution slot. Selection is readiness-based, so a younger ready instruction can issue before an older waiting instruction. This is the main dynamic scheduling behavior validated in Phase 17.

A single common-data-bus-style broadcast wakes dependent entries:

```text
broadcast tag + thread_id -> matching waiting operands become ready
```

Broadcast matching is thread-aware. A broadcast from thread 0 must not wake thread 1, even if the architectural register number or tag-like value would otherwise appear similar.

## Stale Tag Protection

The register-status table only accepts a completing result if the completing tag still matches the current owner tag for that architectural register. This prevents an older stale writer from overwriting a newer writer to the same architectural register.

This is not a full physical-register rename/free-list system. It is a compact experiment showing why tag matching matters.

## Commit Behavior

The model writes architectural state on matching broadcast. That is enough to study reservation stations, wakeup, and tag-based dependency behavior, but it is not precise out-of-order commit.

A production OOO design normally needs a reorder buffer or equivalent retirement structure so instructions can execute out of order but commit in program order with precise recovery. Phase 17 deliberately does not implement that.

## Verification

Run the focused Phase 17 flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1 -SkipPriorRegressions
```

Run the full Phase 17 flow including prior regressions:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_synth.ps1
```

The directed suite currently performs 52 explicit checks. It validates ALU operations, x0 behavior, dependency waiting, wakeup, younger-before-older issue, stale-tag protection, wrong-thread broadcast rejection, per-thread independence, reservation-station full behavior, freed-entry reuse, unsupported-op rejection, trace generation, and report generation.

Reports:

- `reports/perf/tomasulo_summary.md`
- `reports/perf/tomasulo_summary.csv`
- `reports/perf/tomasulo_logs/tomasulo_validation.log`
- `reports/sim/tomasulo_trace.log`
- `sim/phase17_tomasulo.vcd`

## Design Explanation

The useful Design Framing is:

- A scoreboard tells whether registers are busy, but Tomasulo-style scheduling needs reservation stations that remember each instruction's operands, tags, and readiness.
- A reservation station can hold an instruction until its operands arrive. When a producer completes, a CDB-like broadcast wakes all matching consumers.
- Tags let the design distinguish the current producer of a register from an older stale producer. That is why stale result protection is tested.
- Thread ID matters because the same architectural register number in two SMT contexts refers to different architectural state.
- This phase proves the mechanism of readiness-based issue and tag wakeup, not a complete OOO backend.
- A real OOO core still needs physical register renaming, a ROB for precise in-order retirement, load/store ordering, recovery from speculation, and much more robust arbitration.

Good resume wording:

```text
Built a standalone Tomasulo-style scheduling experiment with reservation stations, producer tags, CDB-style wakeup, stale-tag protection, and thread-aware dependency handling.
```

Avoid saying:

```text
Implemented a full out-of-order Tomasulo CPU.
```

## Limitations

Phase 17 does not implement:

- reorder buffer
- precise commit
- physical-register free list
- full register renaming
- load/store queue
- memory disambiguation
- branch speculation or recovery
- multiple functional units
- CDB arbitration among multiple completing units
- production out-of-order execution

## Recommended Phase 18

Phase 18 should add a constrained reorder-buffer and in-order retirement experiment:

- allocate ROB entries with issued instructions
- hold completed results until retirement
- retire in program order
- prevent stale/younger state from becoming architectural early
- keep memory and branch speculation limited and documented
