# Phase 13.6: Dynamic UCP L3 Cache Partitioning

Phase 13.6 upgrades the fixed Phase 13.5 UCP-style partition experiment into a dynamic learning-oriented RTL implementation.

The hierarchy remains:

```text
Pipeline MEM stage -> private L1 bank -> shared L2 -> dynamic UCP-partitioned L3 -> backing memory
```

The CPU still has one pipeline. Logical streams are address-derived, not true cores or SMT threads.

## Algorithm

Policy modes:

- `L3_UCP_POLICY=0`: static equal partition.
- `L3_UCP_POLICY=1`: fixed biased utility-demo partition.
- `L3_UCP_POLICY=2`: dynamic UCP monitor.

The dynamic policy keeps runtime allocation registers:

- `l3_alloc0`
- `l3_alloc1`

The invariant is:

```text
l3_alloc0 + l3_alloc1 = L3_LINES
```

For `L3_LINES=8`, the dynamic controller can choose any split from `1/7` through `7/1`.

## Utility Monitor

The monitor uses simplified shadow tag arrays. On each L3 access, for each stream and each candidate allocation size, the monitor asks:

```text
If this stream had N L3 lines, would this address have hit?
```

It records candidate hit counts for allocation sizes `1` through `L3_LINES-1`.

At the repartition interval boundary, the controller evaluates every split:

```text
score(split k) = stream0_candidate_hits[k] + stream1_candidate_hits[L3_LINES-k]
```

The highest scoring split is selected. Ties keep the current allocation, which avoids unnecessary oscillation.

## Repartition Behavior

When the selected allocation changes:

- the new allocation registers are updated
- all L3 lines are invalidated
- monitor counters and shadow tags are reset
- L1 and L2 behavior is preserved

The full L3 invalidation is intentionally conservative. It avoids stale lines being interpreted under a new partition map. This makes correctness easier to explain, but it can hurt short benchmark performance.

## Validation Result

The `utility_pressure` benchmark passes under all modes:

- static equal: `4/4`
- fixed biased: `6/2`
- dynamic monitor: observed `3/5` after one repartition

The dynamic result is not faster on the short benchmark. This is expected for this first implementation because the monitor repartitions late and invalidates L3, so the remaining program length is not long enough to recover the invalidation cost.

The important Phase 13.6 result is that dynamic repartitioning is now real RTL behavior:

- allocation starts at equal
- utility is estimated from shadow tags
- an exhaustive split search selects a new partition
- L3 is safely invalidated on repartition
- architectural correctness is preserved
- reports include dynamic repartition count and final active allocation

## Interview Notes

Do not describe this as production UCP. Say:

> I implemented a simplified dynamic UCP learning model. It uses shadow tag monitors to estimate utility for each possible two-stream L3 partition, then chooses the split with the highest estimated hit utility. On repartition, it invalidates L3 for correctness. This demonstrates the core control idea behind UCP, but it is not a production cache QoS implementation.

Important details to explain:

- UCP is dynamic because allocation registers can change at runtime.
- The monitor is separate from the real L3 data array.
- Shadow tags estimate utility without changing architectural cache behavior.
- Exhaustive search is practical here because there are only two streams and eight L3 lines.
- Repartition invalidation is safe but expensive.
- A real UCP system would use sampled sets, longer intervals, lower-overhead repartitioning, and true core/thread IDs.

## Limitations

- two logical streams only
- address-derived stream IDs
- direct-mapped one-word-line L3
- no coherence
- no runtime OS/QoS interface
- no multicore or SMT execution
- full L3 invalidation on repartition
- short tests may show worse CPI even when allocation changes correctly
