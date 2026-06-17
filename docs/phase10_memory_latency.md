# Phase 10 Memory Latency

Phase 10 adds a configurable simulation-level data-memory latency model to the pipelined RV32I core. The goal is to study how delayed load/store completion affects stalls and CPI without claiming a realistic cache hierarchy or industrial memory subsystem.

## What Changed

The pipelined core now has a `DMEM_LATENCY_CYCLES` parameter.

- `DMEM_LATENCY_CYCLES = 1`: baseline one-cycle memory behavior.
- `DMEM_LATENCY_CYCLES = 3`: each load/store spends two extra wait cycles in MEM.
- `DMEM_LATENCY_CYCLES = 5`: each load/store spends four extra wait cycles in MEM.

When a valid LW or SW reaches MEM and the configured latency is greater than one, the pipeline holds the PC, IF/ID, ID/EX, and EX/MEM state. MEM/WB receives a bubble while the memory operation waits. The store write-enable is asserted only when the wait completes, and a load writes back only after the wait completes.

## Conservative RAW Interlock

Phase 10 also adds a simple decode-stage RAW interlock. If the instruction in ID reads a register that is still being produced by ID/EX, EX/MEM, or MEM/WB, the frontend is held and a bubble is inserted into EX. This is intentionally conservative: it favors correctness and observability over performance.

This is not forwarding. Forwarding paths are still future work.

## Counters

The core exposes additional counters:

- total stall cycles
- load-use/RAW load stall cycles
- memory stall cycles
- load memory stall cycles
- store memory stall cycles
- load count
- store count

The memory-latency testbench emits a structured `MEMPERF:` line for parsing.

## Benchmarks

Phase 10 adds memory-focused microbenchmarks:

- `tests/benchmarks/mem_load_chain.S`: store, delayed load, immediate dependent consumer, and ALU dependency.
- `tests/benchmarks/mem_store_load.S`: back-to-back stores, back-to-back loads, and dependent add.
- `tests/benchmarks/mem_mixed_latency.S`: memory, ALU dependency, taken branch, and wrong-path commit check.

Each `.S` file is readable assembly intent. The matching `.hex` file is the actual machine-code program loaded by `$readmemh`.

## Running

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_memory_latency_tests.ps1
```

Useful faster iteration command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_memory_latency_tests.ps1 -SkipRegression
```

Reports are written to:

- `reports/perf/memory_latency_summary.md`
- `reports/perf/memory_latency_summary.csv`
- `reports/perf/memory_latency_logs/`

The waveform is:

- `sim/phase10_memory_latency.vcd`

## Limitations

- No cache is implemented in Phase 10.
- No instruction memory latency is modeled yet.
- No forwarding paths are implemented.
- The memory model is educational and deterministic, not a realistic DRAM/controller model.
- CPI numbers are simulation-level microbenchmark estimates, not silicon performance claims.
