# ROB Notes

A reorder buffer is the structure that lets a CPU execute instructions out of order while committing architectural state in program order.

## Lifecycle

```text
Dispatch: allocate ROB entry and rename destination to ROB tag.
Execute: functional unit produces result.
Broadcast: result wakes consumers and marks ROB entry ready.
Commit: oldest ready ROB entry updates architectural state.
```

## Why Broadcast Is Not Commit

Broadcast is an internal availability event. Commit is an architectural event. A younger instruction may broadcast before an older instruction, but it must not retire first if precise in-order state is required.

## Store And Branch Future Work

Stores usually compute address/data early but update memory only at commit. Branches require speculation recovery and checkpoints. Those are intentionally deferred until later phases.

## Phase 19 LSQ Interaction

The Phase 19 LSQ experiment uses the ROB as the architectural commit point for memory operations. Loads mark ROB entries ready when data returns, then update the register file only at ROB commit. Stores hold address/data in the LSQ and update memory only when the store reaches the ROB head. This preserves in-order architectural memory state without implementing speculative store rollback.
