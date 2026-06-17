# Phase 12 Cache Hierarchy Experiment

Phase 12 extends the Phase 11 direct-mapped D-cache into a simplified L1/L2-style data-cache hierarchy experiment. This is a simulation-level educational model, not a production memory hierarchy.

## Structure

```text
Pipeline MEM stage
  -> L1 direct-mapped D-cache
  -> optional L2 direct-mapped backing cache
  -> simple backing memory array
```

The implementation remains in `rtl/direct_mapped_dcache.sv` to preserve the existing pipeline integration point.

## Configuration

Default Phase 12 test configuration:

- L1 lines: 4
- L1 line size: one 32-bit word
- L2 lines: 8
- L2 line size: one 32-bit word
- L2 hit latency: 2 stall cycles
- L2 miss penalty: configurable, tested at 6 and 10 cycles

Pipeline parameters:

- `DCACHE_ENABLE`
- `DCACHE_LINES`
- `L2_ENABLE`
- `L2_LINES`
- `L2_HIT_LATENCY`
- `L2_MISS_PENALTY`

## Policy

The model uses write-through, write-allocate behavior:

- L1 hit store updates L1 and backing memory, and updates L2 if that line is already present.
- L1 miss store goes to L2/backing path, then fills L1 and L2 when L2 is enabled.
- L1 miss load checks L2 when enabled.
- L2 hit returns after `L2_HIT_LATENCY`.
- L2 miss waits `L2_MISS_PENALTY`, fills L2 and L1 from backing memory.

## Counters

Phase 12 reports:

- L1 accesses, hits, misses, hit rate
- L2 accesses, hits, misses, hit rate
- backing memory accesses
- memory stall cycles
- cycles, retired instructions, CPI

## Tests And Reports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_hierarchy_tests.ps1
```

Outputs:

- `reports/perf/cache_hierarchy_summary.md`
- `reports/perf/cache_hierarchy_summary.csv`
- `reports/perf/cache_hierarchy_logs/`
- `reports/sim/cache_hierarchy_trace.log`
- `sim/phase12_cache_hierarchy.vcd`

Benchmarks:

- `repeated_l1_hit`
- `l1_conflict_l2_hit`
- `store_load_policy_check`
- `mixed_l1_l2_program`

## Limitations

- Data-cache path only; no I-cache.
- Direct-mapped L1 and L2 only.
- One word per line.
- No dirty bits, write-back, replacement policy beyond direct mapping, coherence, multicore behavior, or realistic DRAM timing.
- Results are useful for controlled CPI/hit-rate experiments, not signoff memory-system performance.

## UCP Preparation

This phase creates the reporting vocabulary needed for later UCP-style work: per-level accesses, hits, misses, backing-memory pressure, and CPI impact under controlled programs.
