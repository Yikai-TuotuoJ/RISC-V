# UCP Cache Hierarchy Notes

Current cache hierarchy:

```text
Pipeline MEM stage
  -> private L1 D-cache bank selected by logical stream
  -> shared unpartitioned L2
  -> optional shared L3
  -> backing memory
```

When UCP is enabled, only the L3 is partitioned. L1 remains private and L2 remains shared/unpartitioned.

## Why Private L1

Private L1 banks model a normal core-local first-level cache. A core-local L1 avoids immediate capacity interference between streams and keeps the first hit path simple.

## Why Shared L2

The shared L2 acts as a common mid-level cache. In this simplified project, L2 is intentionally not partitioned so both streams can reuse lines before accesses reach the L3 policy experiment.

## Why UCP At L3

UCP is a shared last-level-cache capacity-management idea. Placing UCP at L3 makes the experiment focus on the level where capacity competition is most natural.

## Partition Enforcement

For UCP-enabled L3 modes, stream 0 maps only into its allocated L3 range and stream 1 maps only into its allocated L3 range. With 8 L3 lines:

- equal mode: stream 0 gets 4 lines, stream 1 gets 4 lines
- fixed utility-guided mode: stream 0 gets 6 lines, stream 1 gets 2 lines

The Phase 14 validation suite checks allocation counters, per-stream accesses, hit/miss consistency, and trace-level stream mapping.

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
