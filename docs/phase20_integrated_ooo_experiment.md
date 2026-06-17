# Phase 20: Integrated OOO Experiment Core

Phase 20 consolidates the Phase 17 Tomasulo-style scheduler, Phase 18 ROB, and Phase 19 LSQ concepts into one standalone experimental core: `rtl/ooo_experiment_core.sv`.

This is an integrated OOO-concept core, not a production out-of-order processor.

## Supported Instructions

The experiment supports:

- `ADDI`
- `ADD`
- `SUB`
- `AND`
- `OR`
- `XOR`
- `LW`
- `SW`

Branches, jumps, precise exceptions, full physical register renaming, branch speculation, load replay, and complete memory disambiguation are intentionally excluded.

## Dataflow

```text
issue inputs
  -> dispatch
  -> allocate ROB
  -> allocate RS for ALU uops or LSQ for memory uops
  -> source operands use register-status tags
  -> ready ALU uops issue from RS
  -> ready loads issue from LSQ when conservative ordering allows
  -> CDB broadcasts completed results
  -> ROB records completion
  -> ROB commits in order
  -> stores update memory only at ROB commit
```

## Key Concepts Integrated

Reservation stations hold ALU uops with operand ready bits and producer tags. Ready entries can issue before older waiting entries.

The register-status table maps each architectural destination register to the newest in-flight ROB producer tag. It is a rename-lite mechanism, not a full physical-register renamer.

The CDB-style path broadcasts one completed result per cycle. It marks the ROB entry ready and wakes matching RS and LSQ operands.

The ROB separates completion from architectural commit. Younger completed instructions wait behind an older not-ready head entry.

The LSQ tracks address readiness, store-data readiness, and conservative memory ordering. A younger load waits behind any older unresolved store. Stores update memory only at ROB commit.

## How To Run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_tests.ps1
```

For focused iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_tests.ps1 -SkipPriorRegressions
```

Structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_synth.ps1
```

Outputs:

- `reports/perf/ooo_summary.md`
- `reports/perf/ooo_summary.csv`
- `reports/perf/ooo_logs/ooo_validation.log`
- `reports/sim/ooo_trace.log`
- `sim/phase20_ooo.vcd`

## Interview-Oriented Explanation

A good concise framing:

> I built the project in stages: scoreboard, Tomasulo reservation stations, ROB commit, and LSQ memory ordering. Phase 20 integrates those ideas into a single experimental OOO-style core. ALU uops wait in reservation stations until operands are ready, complete through a CDB-style broadcast, and mark ROB entries ready. The ROB enforces in-order commit, so a younger completed instruction cannot update architectural state before an older instruction. Memory uops go through a limited LSQ: loads wait for address readiness and older unresolved stores, while stores update memory only when they reach ROB commit.

Important limitations to say clearly:

- no branch speculation or rollback
- no precise exception machinery
- no full physical register free list
- no store-to-load forwarding
- no memory-dependence prediction or load replay
- no cache/UCP integration in this final OOO core

This phase demonstrates architecture concepts and verification discipline, not production CPU completeness.
