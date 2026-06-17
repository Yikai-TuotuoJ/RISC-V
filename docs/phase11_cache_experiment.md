# Phase 11 Cache Experiment

Phase 11 adds a small direct-mapped D-cache experiment to the existing 5-stage pipelined RV32I core. This is an educational cache-style RTL model for observing hit/miss behavior, miss stalls, and CPI impact. It is not a production cache hierarchy or realistic DRAM subsystem.

## Implemented Scope

- D-cache only; I-cache is deferred.
- File: `rtl/direct_mapped_dcache.sv`
- Integration point: pipeline MEM stage inside `rtl/rv32i_pipeline_core.sv`
- Default configuration:
  - `DCACHE_ENABLE = 0` for existing non-cache behavior
  - `DCACHE_LINES = 4`
  - `LINE_WORDS = 1` by construction
  - `DCACHE_MISS_PENALTY_CYCLES = 3`
  - word-aligned accesses only

## Cache Organization

The D-cache is direct-mapped. Each line stores:

- valid bit
- tag
- one 32-bit data word

For the default four-line cache, the index uses address bits `[3:2]`. The tag uses the upper address bits above the word offset and index. The backing memory remains a simple word-addressed simulation memory named `mem` inside the D-cache module so testbenches can preload and inspect it.

## Store Policy

Stores use a simple write-through, write-allocate policy:

- Store hit: update the cache line and backing memory.
- Store miss: stall for the configured miss penalty, update backing memory, and fill the selected cache line with the stored data.

This keeps load-after-store behavior deterministic and easy to test. It does not model write buffers, dirty bits, bursts, coherence, or realistic memory timing.

## Miss Penalty And Pipeline Stall

On a cache miss, the D-cache asserts `stall`. The pipelined core reuses the Phase 10 memory-stall contract:

- PC is held.
- IF/ID, ID/EX, and EX/MEM are held.
- MEM/WB receives a bubble while waiting.
- The memory instruction is not lost or double-retired.
- Younger instructions cannot commit ahead of the stalled memory operation.

`DCACHE_MISS_PENALTY_CYCLES` controls the number of reported miss stall cycles. A penalty of 3 produces three memory-stall cycles per miss.

## Counters And Trace

The pipeline exposes D-cache counters:

- D-cache accesses
- D-cache load accesses
- D-cache store accesses
- D-cache hits
- D-cache misses
- D-cache miss stall cycles

The cache testbench writes a human-readable cache trace to:

```text
reports/sim/cache_trace.log
```

Each trace event includes the benchmark, cache enable mode, access type, address, hit/miss status, stall, fill, and running counters.

## Tests And Benchmarks

Run Phase 11 cache tests with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_tests.ps1
```

The runner compares cache-disabled and cache-enabled behavior across:

- `tests/benchmarks/cache/repeated_load.hex`
- `tests/benchmarks/cache/store_load_check.hex`
- `tests/benchmarks/cache/conflict_loads.hex`
- `tests/benchmarks/cache/mixed_cache_program.hex`

Reports are generated at:

```text
reports/perf/cache_summary.md
reports/perf/cache_summary.csv
reports/perf/cache_logs/
```

Correctness is still the pass/fail criterion. Cache hit rate, miss count, stall count, and CPI are diagnostic metrics.

## Current Limitations

- D-cache only; no I-cache yet.
- One 32-bit word per cache line.
- No dirty bits or write-back behavior.
- No write buffer.
- No multi-level cache hierarchy.
- No cache coherence.
- No realistic DRAM timing model.
- No exceptions for misaligned access.

## Resume Framing

Good wording:

- Added a small direct-mapped D-cache experiment with valid/tag/data arrays and hit/miss counters.
- Extended performance reports to compare cache-enabled and cache-disabled memory behavior.
- Built cache-focused microbenchmarks to study CPI impact from miss penalties and conflict behavior.

Avoid claiming a full cache hierarchy, industrial cache verification, cache coherence, or signoff memory performance.
