# Phase 19: Limited LSQ Preparation Experiment

Phase 19 adds a standalone load/store queue preparation experiment on top of the Tomasulo/ROB learning path. The main single-cycle core, pipelined core, SMT experiment, cache/UCP hierarchy, scoreboard model, Tomasulo scheduler, and constrained ROB experiment remain preserved.

## What Was Added

The new RTL module is `rtl/tomasulo_rob_lsq_experiment_core.sv`, with a self-checking testbench at `tb/tb_lsq_experiment.sv`.

Supported operations in this experiment are intentionally small:

- `ADDI`
- `ADD`
- `SUB`
- `LW`
- `SW`

Branches, jumps, full cache integration, speculative replay, store-to-load forwarding, and production memory disambiguation are intentionally not implemented.

## Why LSQ Is Needed

Tomasulo-style ALU scheduling is not enough for memory operations. An ALU operation depends mostly on register operands and functional-unit availability. A memory operation also depends on:

- whether its effective address is known
- whether store data is known
- whether older stores might target the same address
- whether it is safe to update architectural memory
- whether the ROB is ready to commit the memory instruction

The LSQ is the structure that remembers these memory-side facts while instructions wait, wake up, execute, and commit.

## LSQ Entry Contents

Each LSQ entry tracks:

- valid bit
- load/store type
- ROB tag
- program-order sequence ID
- address-ready bit
- computed address value
- address dependency tag when waiting
- store-data-ready bit
- store data value
- store data dependency tag when waiting
- completion state

The sequence ID is used to determine whether a store is older than a load.

## Address Readiness

For both loads and stores:

```text
effective_address = base_register + immediate
```

If the base register is ready at dispatch, the LSQ stores the computed address immediately. If the base register is waiting on a producer tag, the LSQ holds the tag and waits for a matching CDB-style broadcast. A wrong tag must not wake the address dependency.

## Store Data Readiness

Stores also need the source data value. A store may have its address ready while its data is still waiting, or vice versa. The experiment tracks these separately because real store queues must do the same.

A store cannot update memory until both address and data are ready and the ROB reaches that store at the head.

## Conservative Memory Ordering

The experiment uses a deliberately conservative policy:

```text
A younger load waits behind any older unresolved store.
```

This avoids unsafe load bypassing. It is correct, simple, and slower than real speculative memory disambiguation. A real OOO design may allow loads to bypass older stores when it can prove no conflict, and may replay a load if the prediction was wrong. That machinery is deferred.

## ROB Interaction

Loads and stores interact with the constrained ROB differently:

- A load reads memory when its address is ready and conservative ordering allows it.
- The load result marks the corresponding ROB entry ready.
- The architectural register file updates only when the load's ROB entry commits at the head.
- A store may become address/data-ready early, but it writes memory only when its ROB entry reaches commit.

This keeps stores from causing speculative architectural side effects.

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_tests.ps1
```

For faster LSQ-only iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_tests.ps1 -SkipPriorRegressions
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_synth.ps1
```

Generated outputs:

- `reports/perf/lsq_summary.md`
- `reports/perf/lsq_summary.csv`
- `reports/perf/lsq_logs/lsq_validation.log`
- `reports/sim/lsq_trace.log`
- `sim/phase19_lsq.vcd`

The testbench checks load allocation, store allocation, LSQ full stalls, address waits, store-data waits, wrong-tag rejection, load waits behind older unresolved stores, store commit through the ROB, load result commit through the ROB, x0 behavior, and unsupported-op handling.

## Design Explanation

A good Design Framing is:

> I had already built Tomasulo-style reservation station and ROB experiments, but ALU scheduling alone does not solve memory ordering. Phase 19 adds a limited LSQ model that separates memory uops from ALU uops, tracks address readiness and store-data readiness, and forces loads to wait behind older unresolved stores. Stores update memory only at ROB commit, which avoids speculative memory side effects. This demonstrates why real OOO processors need LSQs, memory disambiguation, forwarding, and replay logic, while clearly stopping short of claiming a full production OOO memory subsystem.

Likely follow-up details:

- If asked why stores commit late: stores modify architectural memory, so speculative early stores are dangerous without rollback support.
- If asked why loads wait: an older store with unknown address may target the same address, so bypassing it could read stale data.
- If asked about performance: this conservative policy sacrifices performance for correctness. Memory disambiguation would improve performance by allowing safe bypass.
- If asked about store-to-load forwarding: forwarding would let a younger load receive data from an older ready store to the same address, but this phase intentionally defers it.
- If asked how this connects to ROB: loads mark ROB entries ready when data returns; stores write memory when they reach the ROB head and are address/data-ready.

## Limitations

This phase does not implement:

- full speculative memory execution
- store-to-load forwarding
- memory-dependence prediction
- load violation detection or replay
- branch recovery integration
- precise exception support
- full physical register renaming
- production load/store queue behavior
- cache/UCP integration for speculative memory requests

Future work can connect this LSQ concept to the cache hierarchy and add cautious store-to-load forwarding or memory-disambiguation experiments.

