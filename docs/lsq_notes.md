# LSQ Notes

A load/store queue tracks memory operations after decode/dispatch and before completion/commit. It exists because memory operations have dependencies beyond normal register operands.

## Load Entry

A load entry primarily needs:

- ROB tag for completion
- program-order sequence
- effective address readiness
- effective address value
- dependency tag if the base register is not ready
- completion state

In the Phase 19 model, a load executes only after its address is ready and after every older unresolved store is gone.

## Store Entry

A store entry needs:

- ROB tag for in-order commit
- program-order sequence
- effective address readiness
- store data readiness
- address/data dependency tags when waiting
- committed/completed state

A store can wait for address and data independently. It updates memory only when the ROB reaches the store.

## Conservative Ordering

The model uses:

```text
younger load waits behind any older unresolved store
```

This avoids stale reads without implementing memory disambiguation. It is slower than real OOO memory execution, but it is the right correctness-first step.

## Relationship To Future OOO Memory

A fuller design would add:

- store-to-load forwarding
- address-based disambiguation
- speculative load issue
- load violation detection
- load replay
- cache miss handling
- branch recovery interaction
- precise exception behavior

Phase 19 intentionally implements only the foundation needed to discuss those features clearly.
