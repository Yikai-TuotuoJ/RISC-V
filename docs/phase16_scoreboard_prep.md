# Phase 16: Scoreboard / Reservation-Station Preparation

## Scope

Phase 16 adds a standalone, synthesizable SystemVerilog readiness model. The
existing single-cycle, pipelined, SMT, cache, and UCP RTL paths remain unchanged.

The new model introduces concepts used by later dynamic-scheduling work:

- per-thread architectural-register busy bits
- producer tags for busy registers
- reservation-station-like entries
- source-operand ready bits and source tags
- thread-aware result broadcast and wakeup
- finite entry capacity and full-condition stalls

This is not a Tomasulo CPU. It does not execute instructions, reorder
architectural state, rename registers with a physical-register file, or commit
results out of order.

## RTL Structure

`rtl/scoreboard_issue_model.sv` owns:

- `busy[thread_id][register]`
- `busy_tag[thread_id][register]`
- tag allocation
- issue-time source readiness lookup
- finite-entry allocation
- thread-aware busy-bit clearing on matching completion
- counters

`rtl/reservation_station_entry.sv` stores:

```text
valid, thread_id, op, rd, rs1, rs2
src1_ready, src2_ready
src1_tag, src2_tag
dst_tag
```

An entry is ready when it is valid and both required operands are ready.
Unused operands are marked ready at allocation time. `x0` is always treated as
ready and is never marked busy.

## Broadcast / Wakeup

A completion event supplies:

```text
broadcast_valid
broadcast_thread_id
broadcast_rd
broadcast_tag
```

Waiting entries compare both `thread_id` and tag. A matching source becomes
ready. The scoreboard clears a busy register only when thread ID, architectural
destination register, and tag match. The tag check prevents an older completion
from clearing a newer producer's ownership of the same architectural register.

## SMT Relationship

Busy state is indexed by thread ID. Therefore, thread 0 `x5` and thread 1 `x5`
are independent dependencies. A completion from thread 0 cannot wake a thread 1
reservation entry. This mirrors the per-hardware-thread architectural register
contexts introduced in Phase 15.

## Commit Model

Readiness can become visible in an order different from allocation order, but
Phase 16 has no out-of-order architectural commit path. A future design needs a
carefully defined execution path and a reorder buffer before speculative,
precise out-of-order commit can be claimed.

## Verification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1
```

For fast scoreboard-only iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1 -SkipPriorRegressions
```

Focused lint and synthesis sanity:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_synth.ps1
```

The directed suite checks x0 behavior, basic allocation, one- and two-source
RAW dependencies, cross-thread independence, wrong-thread broadcasts,
multi-entry wakeup, store and branch source waits, full-capacity stalls, entry
reuse, counters, waveform generation, and report generation.

Artifacts:

- `reports/perf/scoreboard_summary.md`
- `reports/perf/scoreboard_summary.csv`
- `reports/sim/scoreboard_trace.log`
- `sim/phase16_scoreboard.vcd`

## Design Explanation

A scoreboard answers: "Which older producer currently owns each source value?"
A reservation station answers: "Has each operand arrived, and is this operation
ready to proceed?" Tags let completions wake only the consumers waiting for that
specific producer. Thread IDs add another namespace so identical architectural
register numbers in different SMT contexts do not alias.

This phase intentionally stops before full Tomasulo. A production out-of-order
backend also needs execution scheduling, robust register renaming, memory-order
handling, recovery, and usually a reorder buffer so speculative execution can
retire in architectural order with precise exceptions.

The honest resume statement is that this phase models and validates dependency
tracking and broadcast wakeup concepts as preparation for dynamic scheduling.

