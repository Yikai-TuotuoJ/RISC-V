# Tomasulo Notes

## What Phase 17 Adds

Phase 17 moves from readiness modeling into a small Tomasulo-style scheduler experiment:

- reservation stations hold pending ALU operations
- register-status entries track the current producer tag for each architectural register
- source operands are either ready values or waiting tags
- a CDB-style broadcast wakes matching operands
- one ready instruction can issue before an older not-ready instruction
- stale producer results are ignored if the register-status table has moved on to a newer tag

## Core Ideas

### Reservation Station

A reservation station is a waiting room for an instruction. It stores the operation, destination, source readiness, source values or source tags, and metadata such as thread ID and sequence ID.

### Register Status / Rename Lite

The register-status table is not a full physical-register rename file. It only says:

```text
this architectural register is waiting for producer tag T
```

That is enough to let later consumers wait for the right producer and to prevent stale producer writes.

### Common Data Bus Concept

The CDB-style broadcast carries:

```text
thread_id, destination register, destination tag, result data
```

Reservation stations compare their waiting source tags against the broadcast tag. Matching entries mark that source ready and capture the data.

### Dynamic Scheduling

Dynamic scheduling means issue can depend on operand readiness rather than only program order. In this experiment, a younger ready ALU instruction can issue while an older instruction waits for a source tag.

## What Is Still Missing

A complete Tomasulo or OOO backend needs more than this:

- ROB for precise in-order retirement
- physical register renaming and free-list management
- memory ordering and load/store queue
- branch speculation and recovery
- exception/interrupt precision
- multiple functional units and arbitration

Phase 17 is useful because it isolates the scheduling and wakeup concepts before adding those heavier correctness mechanisms.
## Phase 18 ROB Extension

Phase 18 keeps the Tomasulo-style scheduler experimental and adds a constrained ROB model. Reservation stations still decide readiness and issue. The CDB still broadcasts completion. The new difference is that architectural register state updates only from ROB head commit, not from raw broadcast.

This demonstrates the central OOO distinction: execution can complete out of order, but commit must happen in program order when precise architectural state matters.

## Phase 19 LSQ / Memory Ordering Note

Phase 19 extends the experimental Tomasulo/ROB path with a limited load/store queue preparation model. Memory operations are allocated into LSQ entries, track address readiness, track store-data readiness, and interact with ROB commit. The model uses conservative ordering: a load waits behind any older unresolved store. Stores write memory only when the ROB reaches the store entry.

This is not full speculative memory execution. Store-to-load forwarding, memory disambiguation, violation replay, cache miss replay, and production LSQ behavior remain future work.
