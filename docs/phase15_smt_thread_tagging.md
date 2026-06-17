# Phase 15 SMT-Style Thread Tagging

Phase 15 adds a separate experimental SMT-style pipeline core. The original single-thread pipeline remains the reference design.

## Model

The new `rv32i_smt_pipeline_core.sv` supports two logical threads. Each thread has its own PC and architectural register state. The pipeline carries a one-bit `thread_id` through IF/ID, ID/EX, EX/MEM, and MEM/WB so decode, hazard checks, writeback, branch redirect, tracing, and cache/UCP stream selection know which architectural context is active.

Fetch uses a deterministic round-robin policy. The design fetches thread 0, then thread 1, then repeats. A shared memory/cache stall conservatively stalls the full pipeline. Branch and jump redirect update the PC for the resolving thread. The current implementation uses a conservative global flush for correctness.

## Hazard Strategy

The SMT core uses a conservative interlock rather than aggressive bypass forwarding. RAW checks compare both register number and `thread_id`. This is the critical SMT rule: x3 in thread 0 and x3 in thread 1 are different architectural registers and must not forward or stall each other.

Writeback also carries `thread_id`, so only the matching register bank is written. x0 is forced to zero independently for both threads.

## Cache/UCP Integration

`direct_mapped_dcache.sv` now has `STREAM_ID_MODE` and `req_thread_id`.

- `STREAM_ID_MODE = 0`: legacy address-derived stream ID.
- `STREAM_ID_MODE = 1`: stream ID comes from the pipeline thread ID.

In SMT mode, thread 0 maps to stream 0 and thread 1 maps to stream 1. The existing private-L1/shared-L2/UCP-L3 hierarchy and dynamic UCP shadow monitor are reused. This is the bridge from earlier address-derived stream experiments toward real pipeline-carried thread identity.

## Verification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1
```

For faster SMT-only iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1 -SkipPriorRegressions
```

The runner generates deterministic SMT programs, runs six simulations, fails if fewer than 20 meaningful checks execute, and writes:

- `reports/perf/smt_summary.md`
- `reports/perf/smt_summary.csv`
- `reports/perf/smt_ucp_summary.md`
- `reports/perf/smt_ucp_summary.csv`
- `reports/sim/smt_trace.log`
- `reports/sim/smt_ucp_trace.log`

## Design Notes

The important idea is metadata discipline. Once multiple logical instruction streams share a pipeline, the pipeline must know which architectural context each in-flight instruction belongs to. That means thread IDs are not just debug labels; they are part of the correctness path for register reads, writeback, hazards, branch redirect, counters, and cache attribution.

This is not production SMT. There is no register renaming, ROB, superscalar issue, or out-of-order scheduling. It is an in-order two-thread experiment that demonstrates the core RTL concept: thread-tagged pipeline state and thread-aware memory/cache accounting.


