# Phase 14: Active UCP Cache-Hierarchy Validation

Phase 14 is a validation and stress-testing phase. It does not add SMT, Tomasulo, out-of-order execution, coherence, or a new CPU execution feature.

The active hierarchy under test is:

```text
Pipeline MEM stage
  -> private L1 D-cache bank selected by address-derived logical stream ID
  -> shared unpartitioned L2 cache
  -> shared L3 cache, optionally UCP-partitioned
  -> backing memory
```

The project still has one CPU pipeline. Logical streams are derived from the data address:

```text
stream 0: addr < STREAM_SPLIT_ADDR
stream 1: addr >= STREAM_SPLIT_ADDR
```

The Phase 14 testbench configuration uses `STREAM_SPLIT_ADDR = 32'h00000080` for the current compact benchmark address map.

## Policy Modes Validated

The Phase 14 runner maps the requested conceptual modes onto the current RTL parameters:

| Phase 14 mode | RTL configuration | Meaning |
|---|---|---|
| `mode0_l3_disabled` | `L3_ENABLE=0`, `L3_UCP_ENABLE=0` | Baseline with private L1/shared L2 and no L3 |
| `mode1_l3_unpartitioned` | `L3_ENABLE=1`, `L3_UCP_ENABLE=0` | Shared L3 is enabled but not partitioned |
| `mode2_l3_equal` | `L3_ENABLE=1`, `L3_UCP_ENABLE=1`, `L3_UCP_POLICY=0` | Equal UCP split, 4 lines for stream 0 and 4 for stream 1 |
| `mode3_l3_utility_fixed` | `L3_ENABLE=1`, `L3_UCP_ENABLE=1`, `L3_UCP_POLICY=1` | Fixed utility-guided demonstration split, 6 lines for stream 0 and 2 for stream 1 |

Dynamic UCP policy `2` from Phase 13.6 remains available, but Phase 14 focuses on active validation and comparison of disabled, unpartitioned, equal, and fixed utility-guided modes.

## What The Validation Checks

The runner executes real RTL simulations and parses the `UCPRTL:` counter lines. It fails on missing fields, failed architectural checks, counter inconsistencies, missing reports, or fewer than 20 meaningful checks.

The generated checks cover:

- final architectural correctness through the existing testbench PASS path
- timeout and illegal-instruction detection
- `x0` correctness through testbench register checks
- private L1 stream 0 and stream 1 counter consistency
- shared L2 hit/miss/access consistency
- per-stream L3 hit/miss/access consistency
- L3 allocation behavior for equal and fixed utility-guided policies
- L3 disabled fallback to backing memory
- unpartitioned L3 activity
- shared L2 reuse with both logical streams
- L3 reuse after L1/L2 pressure
- utility-pressure policy comparison
- trace-level stream-ID mapping from address to logical stream
- allocation sum invariants in the trace

## Reports

Run:

```powershell
.\scripts\run_phase14_ucp_validation.ps1
```

Fast development run:

```powershell
.\scripts\run_phase14_ucp_validation.ps1 -SkipRegressions -SkipLint -SkipSynth
```

Generated reports:

```text
reports/phase14_ucp/ucp_validation_summary.md
reports/phase14_ucp/ucp_validation_summary.csv
reports/phase14_ucp/ucp_policy_comparison.md
reports/phase14_ucp/ucp_policy_comparison.csv
reports/phase14_ucp/ucp_counter_consistency.md
reports/phase14_ucp/ucp_trace.log
```

## Interview-Oriented Analysis

Private L1 caches are common because the closest cache is latency-sensitive and usually tied to one core's immediate load/store path. In this project, private L1 banks are selected by logical stream ID, which models the capacity-isolation idea before the project has real multicore or SMT execution.

The L2 remains shared and unpartitioned. That is intentional: it lets both logical streams reuse recently fetched data before the last-level-cache policy matters. This keeps the model smaller and makes the L3 partition behavior easier to isolate.

UCP naturally belongs at a shared last-level cache because that is where multiple workloads compete for capacity. Partitioning at L3 can protect one stream's useful hot set from being evicted by another stream's streaming/conflict-heavy accesses.

The fixed utility-guided policy is not full production UCP. It is a deterministic demonstration of the kind of result a utility-based allocator might choose: stream 0 gets more lines because the current utility-pressure benchmark gives stream 0 a reusable hot set. The validation compares this with equal partitioning and checks that the cache counters move in the expected direction.

Hit rate alone is not enough. The validation also checks architectural state, stream mapping, quota allocation, counter consistency, and backing-memory pressure. A policy that improves hit rate but corrupts memory, violates partition boundaries, or lets wrong-path state commit would be unacceptable.

## Limitations

- The project still has one CPU pipeline.
- Logical streams are address-derived, not real hardware thread IDs.
- There is no multicore cache coherence.
- The fixed utility-guided mode is not runtime stack-distance UCP.
- The cache model is educational and deterministic, not a production shared-cache QoS controller.

## Dynamic UCP Validation Update

Phase 14 now treats dynamic UCP as a primary validation mode, not merely a future idea. The added mode is:

```text
mode4_dynamic_ucp: L3 enabled, UCP enabled, dynamic monitor policy
```

The dynamic mode starts from the equal split, monitors L3 behavior, evaluates candidate allocations, and repartitions at interval boundaries. The validation checks that dynamic allocation remains legal, that each stream keeps at least one L3 line, that the allocation sum equals the total L3 line count, and that the pressure benchmark actually triggers repartitioning.

The fixed utility-guided policy remains only as a comparison point. It is useful for showing what an idealized deterministic allocation can look like, but it is not the main UCP claim.

## Long Dynamic UCP Benchmark Result

A longer benchmark, `dynamic_ucp_long_stream1`, was added to show a case where dynamic UCP can outperform equal partitioning. The program has two phases:

1. A warm-up/pressure phase that gives the dynamic monitor enough L3 accesses to repartition.
2. A longer stream-1 hot-set phase that repeatedly accesses five stream-1 cache lines.

With an equal 4/4 split, stream 1 cannot retain the five-line hot set as effectively. Dynamic UCP repartitions to 3/5 and gives stream 1 enough L3 capacity to improve reuse.

Observed result:

```text
equal partition:  cycles=502 L3 hits=16 backing accesses=20
dynamic UCP:      cycles=462 L3 hits=21 backing accesses=15 final alloc=3/5
fixed 6/2 policy: cycles=582 L3 hits=6  backing accesses=30
```

This is the right interview framing: dynamic UCP has overhead and may not win on short programs, but on a longer phase-changing workload it can adapt and outperform a static equal split or a fixed allocation biased toward the wrong stream.
