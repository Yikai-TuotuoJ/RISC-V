# Phase 13.5: RTL Private L1 / Shared L2 / UCP L3 Experiment

Phase 13.5 converts the Phase 13 UCP-style idea from a trace-only policy model into a pipeline-integrated RTL cache hierarchy experiment.

The hierarchy is:

```text
Pipeline MEM stage
  -> private L1 D-cache bank selected by logical stream ID
  -> shared unpartitioned L2 cache
  -> shared UCP-partitioned L3 cache
  -> backing memory
```

The project still has one CPU pipeline. Logical cores are modeled as address-derived streams, not real hardware cores or SMT threads.

## Design

The implementation extends `rtl/direct_mapped_dcache.sv` while preserving the existing CPU/cache integration point.

Important parameters:

- `PRIVATE_L1_ENABLE`
- `L1_NUM_CORES`
- `L3_ENABLE`
- `L3_LINES`
- `L3_UCP_ENABLE`
- `L3_UCP_POLICY`
- `STREAM_SPLIT_ADDR`
- `L3_HIT_LATENCY`
- `L3_MISS_PENALTY`

Stream selection:

```text
stream 0: addr < STREAM_SPLIT_ADDR
stream 1: addr >= STREAM_SPLIT_ADDR
```

The default split remains `32'h00001000`, but Phase 13.5 tests override it to `32'h00000080` so both streams fit inside the small backing-memory model.

## Cache Roles

### Private L1

Each logical stream selects its own L1 bank. This models the common CPU design idea that the closest cache is private to a core. In this project it is still a logical model, because there is only one pipeline.

### Shared L2

L2 remains shared and unpartitioned. Both streams can use all L2 lines. This preserves the Phase 12 idea and intentionally avoids making L2 the UCP target.

### UCP-Partitioned L3

L3 is the shared last-level cache experiment. UCP-style partitioning is applied only at L3.

For `L3_LINES=8`:

- equal policy: stream 0 gets 4 lines, stream 1 gets 4 lines
- utility-guided fixed policy: stream 0 gets 6 lines, stream 1 gets 2 lines

This is a fixed-quota educational approximation. It is not runtime UCP allocation.

## Verification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

For Phase 13.5 only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1 -SkipRegression -SkipCacheHierarchy
```

RTL benchmarks live under:

- `tests/benchmarks/ucp_rtl/shared_l2_reuse.hex`
- `tests/benchmarks/ucp_rtl/l3_reuse_after_l2_eviction.hex`
- `tests/benchmarks/ucp_rtl/utility_pressure.hex`

The testbench checks:

- final register state
- x0 remains zero
- no illegal instruction
- no timeout
- L1/L2/L3 counter consistency
- per-stream L3 counter consistency
- L3 quota values
- shared L2 hit behavior
- L3 hit behavior after L2 eviction
- utility-guided policy improving the pressure benchmark

## Reports

Outputs:

- `reports/perf/ucp_partition_summary.md`
- `reports/perf/ucp_rtl_partition_summary.md`
- `reports/perf/ucp_rtl_partition_summary.csv`
- `reports/perf/ucp_rtl_logs/`
- `reports/sim/ucp_rtl_trace.log`
- `sim/phase13_5_ucp_cache.vcd`

## Design Notes

The important story is not that this is a complete UCP implementation. The important story is that the design separates cache levels by role:

- private L1 for local fast reuse
- shared L2 for common mid-level reuse
- partitioned L3 as the shared capacity-management point

The `utility_pressure` benchmark demonstrates why partitioning can matter: a hot reusable stream can benefit from more last-level cache capacity, reducing L3 misses and backing-memory accesses.

## Limitations

- No real multicore execution.
- No hardware thread ID path yet.
- No cache coherence.
- No runtime utility monitor or dynamic repartition interval.
- Direct-mapped, one-word-line educational cache model.
- Fixed quotas only: equal vs utility-guided.

