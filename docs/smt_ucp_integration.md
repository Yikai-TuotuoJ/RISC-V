# SMT/UCP Integration

Earlier UCP experiments used address-derived streams because the CPU had only one architectural thread. Phase 15 adds a cleaner source: pipeline-carried thread ID.

## Stream Selection

The D-cache hierarchy supports two modes:

```text
STREAM_ID_MODE = 0: stream = addr >= STREAM_SPLIT_ADDR
STREAM_ID_MODE = 1: stream = req_thread_id
```

Legacy Phase 13/14 tests continue to use address-derived streams. SMT tests use thread-derived streams so thread 0 drives stream 0 counters and thread 1 drives stream 1 counters.

## Why This Matters

UCP is a shared-cache policy. In a real multicore or SMT design, cache utility should be attributed to the hardware thread or core causing the accesses. Address-derived streams were useful for early experiments, but they do not represent true execution context. Thread-derived streams make the L1/L2/L3 reports more meaningful.

## Current Limitations

- Two logical threads only.
- One shared in-order pipeline.
- Shared data memory and cache hierarchy.
- Conservative global memory stall.
- Conservative global control flush.
- Dynamic UCP shadow monitoring is preserved, but short SMT tests do not force repartitioning; the longer Phase 14 dynamic UCP benchmark remains the stronger repartition demonstration.

