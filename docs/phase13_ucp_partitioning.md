# Phase 13: Simplified UCP-Style Cache Partitioning

Phase 13 adds a simplified Utility-Based Cache Partitioning (UCP) style experiment.

This phase does not add a hardware thread model, multicore support, cache coherence, or a production UCP controller. Instead, it adds a deterministic trace-level shared-cache policy model that compares partitioning policies on controlled memory-access streams.

## Model Type

The implementation is a Python trace replay model:

- Script: `scripts/ucp_partition_model.py`
- Runner: `scripts/run_ucp_tests.ps1`
- Trace directory: `tests/benchmarks/ucp/`
- Reports:
  - `reports/perf/ucp_partition_summary.md`
  - `reports/perf/ucp_partition_summary.csv`
  - `reports/perf/ucp_logs/`

The model treats each trace label, such as `A` or `B`, as a logical workload or stream. These are not hardware thread IDs. They are workload labels used to study how cache allocation affects hit/miss behavior.

## Trace Format

Each non-comment trace line has this form:

```text
<workload> <op> <address>
```

Example:

```text
A R 0x00000100
B R 0x00001000
```

Supported operations are `R` and `W`. The current reports focus on hit/miss and estimated miss penalty behavior, not store ordering or coherence.

## Cache Model

The default shared-cache model is intentionally small:

- total logical shared-cache lines: 4
- line size: 4 bytes
- replacement within each workload partition: LRU
- miss penalty used for estimates: 10 cycles

The cache is partitioned by workload. A workload can only occupy up to its allocated number of lines.

## Policies

### Static Equal Partition

The equal policy divides lines evenly across workloads.

For two workloads and four total lines:

```text
A = 2 lines
B = 2 lines
```

### Utility-Guided Partition

The utility-guided policy evaluates legal allocations and chooses the one with:

1. most total hits
2. fewest total misses
3. closest-to-equal allocation as a deterministic tie breaker

For two workloads and four lines, the legal allocations are:

```text
A=1, B=3
A=2, B=2
A=3, B=1
```

This is a simplified utility-guided approximation. It is not a full UCP stack-distance implementation.

## Benchmarks / Traces

Current traces are:

- `trace_hot_array_vs_stream.txt`
  - Workload A repeatedly touches a small hot set.
  - Workload B streams through mostly unique addresses.
- `trace_balanced_hotsets.txt`
  - Both workloads have small hot sets.
  - Equal partitioning is expected to be near optimal.
- `trace_mixed_utility.txt`
  - Workload A has a three-line reusable set.
  - Workload B has a smaller hot point plus noise.
  - Utility-guided allocation can shift lines toward A.

## Running

From PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

For UCP-only validation without rerunning earlier regressions:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1 -SkipRegression -SkipCacheHierarchy
```

## Report Interpretation

The Markdown and CSV reports include:

- benchmark or trace name
- policy name
- workload label
- allocated cache lines
- accesses
- hits
- misses
- hit rate
- miss rate
- estimated miss penalty cycles
- total policy penalty cycles

Because this is trace-level, the report uses estimated penalty cycles. It does not claim pipeline-integrated CPI.

## Why This Is Useful

This phase makes shared-cache policy tradeoffs visible before adding SMT or multicore machinery. It demonstrates:

- how partition size affects hit/miss behavior
- why streaming workloads may have low cache utility
- how a utility-guided policy can favor a workload that benefits more from extra cache capacity
- how to generate reproducible policy-comparison reports

## Limitations

- No SMT or hardware thread IDs are implemented.
- No cache coherence is modeled.
- No RTL shared-cache partition controller is implemented.
- The model uses logical workload labels in traces.
- Estimated penalty cycles are based on a fixed miss penalty.
- This is not production UCP, cache QoS, or industrial cache management.
