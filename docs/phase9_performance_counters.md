# Phase 9: Performance Counters and Benchmark-Style Reporting

Phase 9 adds simulation-level performance counter reporting for the pipelined CPU. It does not add new architecture features.

## Counters

The pipelined core now exposes raw counters for:

- cycles
- retired instructions
- stalls
- load-use stalls
- flushes
- branch/jump flushes
- loads
- stores

The existing branch prediction counters are reused for:

- conditional branches
- taken branches
- not-taken branches
- correct predictions
- mispredictions

The benchmark testbench also computes program-bounded counters from pipeline trace signals. This avoids counting the trailing NOPs that exist after the benchmark program in instruction memory.

## Retired Instruction Definition

For benchmark reports, an instruction is counted as retired when:

- it is valid in WB
- it was not flushed
- it is within the benchmark address range

Stores and branches count as retired when their valid instruction reaches WB, even though they do not write a register. Bubbles, invalid slots, and wrong-path flushed instructions do not count.

## CPI

CPI is computed as:

```text
CPI = cycles / retired_instruction_count
```

If retired count is zero, CPI is treated as unavailable. In the current reports, all benchmark runs retire at least one instruction.

This is a simulation-level CPI estimate for controlled microbenchmarks, not a silicon performance number.

## Benchmarks

Benchmarks live under `tests/benchmarks/`:

- `alu_chain`: scheduled dependent ALU increments
- `mem_stream`: scheduled store/load sequence
- `branch_loop`: small loop with repeated conditional branches
- `mixed_program`: memory, ALU, and taken branch behavior

Each benchmark checks deterministic final architectural state before printing a `PERF:` line.

## Running

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_benchmarks.ps1
```

The runner executes each benchmark in three predictor modes:

- `none`
- `simple`
- `gshare`

Outputs:

- `reports/perf/benchmark_logs/`
- `reports/perf/benchmark_summary.md`
- `reports/perf/benchmark_summary.csv`
- `sim/phase9_benchmark.vcd`

## Current Limitations

- Stall and load-use stall counters are currently zero because this baseline still uses scheduled tests and does not yet model explicit load-use stall hardware.
- The benchmark programs are small controlled microbenchmarks, not industry-standard workloads.
- Predictor accuracy is workload-dependent; correctness is still based on architectural state.
- The gshare predictor does not always outperform the simple predictor on short cold-start branch streams.

