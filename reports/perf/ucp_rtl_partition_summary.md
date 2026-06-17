# RTL UCP Cache Partition Summary

This report is generated from the pipeline-integrated Phase 13.5 RTL cache hierarchy:

```text
Pipeline MEM stage -> private L1 bank -> shared L2 -> UCP-partitioned L3 -> backing memory
```

The design still has one CPU pipeline. Logical cores/streams are derived from address regions for this experiment.

| benchmark | policy | pass | cycles | CPI | L1 hits/misses | L2 hits/misses | L3 alloc S0/S1 | L3 S0 hits/misses | L3 S1 hits/misses | backing accesses | repartitions |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| l3_reuse_after_l2_eviction | 0 | PASS | 128 | 8.000 | 0/8 | 0/8 | 4/4 | 1/4 | 1/2 | 6 | 0 |
| shared_l2_reuse | 0 | PASS | 90 | 7.500 | 0/6 | 2/4 | 4/4 | 0/2 | 0/2 | 4 | 0 |
| utility_pressure | 2 | PASS | 221 | 8.500 | 0/13 | 0/13 | 3/5 | 1/8 | 0/4 | 12 | 1 |
| utility_pressure | 0 | PASS | 205 | 7.885 | 0/13 | 0/13 | 4/4 | 2/7 | 1/3 | 10 | 0 |
| utility_pressure | 1 | PASS | 181 | 6.962 | 0/13 | 0/13 | 6/2 | 6/3 | 0/4 | 7 | 0 |

## Interview-Oriented Analysis

- On `utility_pressure`, utility-guided L3 partitioning increased L3 hits by 3 and reduced backing-memory accesses by 3 versus equal partitioning.
- The same benchmark reduced simulated cycles by 24 in this controlled setup, because fewer L3 misses reached backing memory.
- Private L1 banks model the common CPU idea that the closest cache is core-local and latency-sensitive.
- The L2 remains shared and unpartitioned, so both logical streams can reuse recently fetched lines before the L3 policy matters.
- UCP is placed at L3 because a last-level cache is where capacity sharing and partitioning policy are most natural.
- Address-derived stream IDs are an educational stand-in for future thread/core IDs; this is not multicore execution or coherence.
- Correctness checks include architectural register state, x0, no illegal instruction, counter consistency, and partition quota checks, not just hit-rate improvements.
- Policy `2` adds a simplified dynamic UCP monitor that uses shadow tags, exhaustive split search, and safe L3 invalidation on repartition.
- This is still an educational two-stream UCP model, not production cache QoS, coherence, or multicore runtime management.
