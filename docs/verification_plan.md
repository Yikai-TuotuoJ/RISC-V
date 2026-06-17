# Verification Plan

## Regression Flow

Primary Windows command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_pipeline_tests.ps1
```

The runner executes:

- Phase 1 single-cycle directed simulation
- Phase 2 single-cycle memory/branch simulation
- Phase 3 single-cycle jump/upper-immediate simulation
- Phase 4 baseline pipeline directed simulation
- Phase 5 trace logging simulation
- Phase 5 randomized hazard-free simulation
- Phase 6 branch predictor directed simulation
- Phase 7 gshare branch predictor directed simulation
- Phase 8 Yosys synthesis report generation
- Phase 9 benchmark-style performance reporting
- Phase 10 memory-latency benchmark reporting
- Phase 10.5 SystemVerilog `.sv` / `-g2012` compatibility regression
- Phase 5 Verilator lint, when available
- Phase 5 Yosys synthesis sanity, when available

Logs are saved under `reports/sim/` where practical. Lint and synthesis reports are also saved under `reports/`.

## Directed Tests

Directed tests cover the supported architectural subset and explicit control-flow cases:

- ALU operations
- ADDI
- LW and SW
- BEQ and BNE taken/not-taken behavior
- JAL and JALR target/link behavior
- LUI and AUIPC
- wrong-path instruction flushing on taken redirect
- branch prediction learning, misprediction redirect, and wrong-path commit prevention
- x0 hardwired-zero behavior

## Random Tests

The Phase 5 random generator produces deterministic hazard-free tests from a fixed or user-provided seed. It writes assembly-like text, hex machine code, and expected architectural state.

The random generator currently avoids branch and jump generation, and it inserts NOPs to avoid unsupported data hazards.

## Branch Predictor Tests

Phase 6 adds a directed branch-prediction test:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1
```

The test checks a repeated BNE loop, a taken BEQ with wrong-path instructions, a not-taken BNE, final architectural state, branch counters, prediction counters, misprediction count, and report generation.

The branch prediction report is written to `reports/sim/branch_prediction_report.log`. A cycle-by-cycle pipeline trace with branch-prediction fields is written to `reports/sim/branch_prediction_trace.log`.

## Gshare Tests

Phase 7 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_gshare_tests.ps1
```

The gshare flow runs the existing pipeline regression, the Phase 6 simple-predictor regression, and a branch-heavy gshare test. The gshare test checks final architectural state, wrong-path write prevention, branch counters, GHR update, report generation, and same-program comparison against the simple predictor.

The report is written to `reports/sim/gshare_branch_prediction_report.log`. The trace is written to `reports/sim/gshare_branch_prediction_trace.log`.

## Synthesis Report Checks

Phase 8 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_synth_reports.ps1
```

The script runs Yosys for the single-cycle wrapper, pipeline/no-prediction wrapper, and pipeline/gshare wrapper. It emits logs, generic synthesized netlists, JSON files, and summary tables under `reports/synth/`.

This is a synthesis sanity and comparison flow. It does not replace simulation regression and does not claim timing signoff.

## Benchmark Performance Checks

Phase 9 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_benchmarks.ps1
```

The script runs controlled microbenchmarks across no-prediction, simple-predictor, and gshare modes. Each run checks final architectural state, emits one structured `PERF:` line, and contributes to Markdown/CSV summaries under `reports/perf/`.

Performance counters are useful for comparison, but benchmark pass/fail is still based on correctness.

## Current Gaps

The pipeline currently lacks forwarding and load-use stall logic. Tests that require back-to-back dependent instructions, EX/MEM forwarding, MEM/WB forwarding, or load-use stalls are not enabled as passing regression tests yet.

Those tests should be added together with the hazard/forwarding implementation, before claiming the pipeline handles unscheduled code.

## Memory Latency Checks

Phase 10 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_memory_latency_tests.ps1
```

The script runs memory-focused benchmarks with `DMEM_LATENCY_CYCLES` values of 1, 3, and 5. Each run checks final architectural state and emits a structured `MEMPERF:` line. Markdown and CSV summaries are generated under `reports/perf/`.

Correctness remains the pass/fail criterion. CPI and memory-stall counts are diagnostic metrics for comparing controlled latency settings.

## SystemVerilog Compatibility Checks

Phase 10.5 migrated source RTL and testbenches to `.sv`. Icarus flows use `-g2012`, and Yosys synthesis scripts use `read_verilog -sv`. The same behavioral regressions remain the proof that the refactor preserved architectural behavior.

## Cache Experiment Checks

Phase 11 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_tests.ps1
```

The cache flow runs directed cache microbenchmarks with cache disabled and enabled. It checks final architectural state, x0 behavior, backing-memory contents, cache hit/miss counters, and miss-stall reporting. Results are summarized in `reports/perf/cache_summary.md` and `reports/perf/cache_summary.csv`, with detailed logs under `reports/perf/cache_logs/`.

Cache correctness is judged by architectural state. Hit rate and CPI are comparison metrics, not proof of production cache performance.


## Cache Hierarchy Checks

Phase 12 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_hierarchy_tests.ps1
```

The flow runs cache hierarchy microbenchmarks across cache-disabled, L1-only, and L1+L2 modes. Each run checks final architectural state and emits a structured `HIERPERF:` line. Reports are generated at `reports/perf/cache_hierarchy_summary.md` and `reports/perf/cache_hierarchy_summary.csv`.

The `l1_conflict_l2_hit` test intentionally uses two addresses that conflict in the 4-line L1 but occupy different positions in the 8-line L2, creating a visible L1 miss / L2 hit case.

## UCP-Style Partition Checks

Phase 13 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

The full runner executes the existing pipeline/cache hierarchy flow and then runs the simplified UCP-style trace model. The UCP model compares static equal partitioning against utility-guided partitioning on deterministic two-workload traces.

Reports are generated at:

- `reports/perf/ucp_partition_summary.md`
- `reports/perf/ucp_partition_summary.csv`
- `reports/perf/ucp_logs/`

Correctness for Phase 13 means the policy model is deterministic, partition quotas are respected, hit/miss accounting is internally consistent, and utility-guided allocation does not perform worse than equal allocation on the provided traces. These checks are policy-model checks, not RTL cache-coherence checks.

## Phase 13.5 RTL UCP Cache Checks

Phase 13.5 extends `scripts/run_ucp_tests.ps1` with pipeline-integrated RTL checks for a private-L1/shared-L2/UCP-L3 hierarchy. The tests verify architectural state and cache-policy counters.

The RTL tests cover shared L2 reuse, L3 hits after L2 eviction, equal L3 partitioning, utility-guided fixed L3 partitioning, per-stream counter consistency, and quota reporting.

## Phase 13.6 Dynamic UCP Verification

The UCP RTL runner now compares static equal, fixed biased, and dynamic monitor modes. Dynamic mode checks allocation sum, minimum per-stream allocation, at least one repartition, architectural register correctness, x0, no illegal instruction, L1/L3 counter consistency, and report generation.


## Phase 14 Active UCP Validation

Phase 14 validates the cache hierarchy with real RTL simulations across four modes: L3 disabled, L3 unpartitioned, equal UCP partition, and fixed utility-guided UCP partition. The runner fails if fewer than 20 meaningful checks execute, if required counters are missing, if counter consistency fails, or if required Markdown/CSV reports are absent.

Primary command:

```powershell
.\scripts\run_phase14_ucp_validation.ps1
```

Primary reports:

```text
reports/phase14_ucp/ucp_validation_summary.md
reports/phase14_ucp/ucp_policy_comparison.md
reports/phase14_ucp/ucp_counter_consistency.md
```

## Phase 15 SMT Checks

Phase 15 adds:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1
```

The flow generates deterministic two-thread programs and runs checks for per-thread register isolation, x0 behavior, independent PC/fetch accounting, same-thread RAW stalls, cross-thread same-register independence, load/store correctness, branch/jump redirect behavior, thread-ID-driven UCP stream mapping, cache counter consistency, and report generation.

The runner fails if fewer than 20 meaningful SMT checks execute. Current reports are generated under `reports/perf/`, and trace logs are generated under `reports/sim/`.

## Phase 16 Scoreboard Checks

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1
```

The runner first preserves the prior SMT/cache/UCP regression reference, then
compiles and executes the standalone scoreboard validation suite. The suite
fails if fewer than 20 meaningful checks run, if any explicit check fails, or
if the required Markdown, CSV, and trace outputs are absent.

Coverage includes x0 handling, per-thread busy state, one- and two-source RAW
dependencies, source tags, thread-aware wakeup, wrong-thread broadcast
rejection, multi-entry wakeup, store and branch readiness, entry-capacity
stalls, released-entry reuse, and summary counters.

## Phase 17 Tomasulo-Style Checks

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1
```

The runner preserves the prior scoreboard/SMT/cache/UCP regression reference, then runs the standalone Tomasulo validation suite. For focused iteration, use `-SkipPriorRegressions`.

The Phase 17 testbench fails if fewer than 20 meaningful checks execute or if any explicit check fails. Current coverage includes all supported ALU operations, x0 behavior, dependency waiting, CDB wakeup, younger-before-older dynamic issue, stale-tag protection, wrong-thread broadcast rejection, thread-local register state, reservation-station full behavior, freed-entry reuse, unsupported-op rejection, report generation, and trace generation.

Reports are generated at `reports/perf/tomasulo_summary.md` and `reports/perf/tomasulo_summary.csv`; detailed logs are under `reports/perf/tomasulo_logs/`; the trace is `reports/sim/tomasulo_trace.log`.

## Phase 18 ROB Verification

Run `scripts\run_rob_tests.ps1`. The testbench performs 56 explicit checks and fails if fewer than 20 meaningful ROB checks run. It validates ROB allocation/reuse, full stalls, ROB-tag source dependencies, CDB completion, wakeup, x0 suppression, stale-tag protection, head-not-ready commit stalls, younger-completed-waiting behavior, and final committed results for ADD/SUB/AND/OR/XOR/ADDI.

## Phase 19 LSQ Verification

Run `scripts/run_lsq_tests.ps1` to validate the limited LSQ preparation experiment. The runner compiles `tb_lsq_experiment.sv`, requires at least 20 meaningful checks, generates `reports/perf/lsq_summary.md`, `reports/perf/lsq_summary.csv`, and writes `reports/sim/lsq_trace.log`.

The checks cover load/store allocation, LSQ full detection, freed entry reuse, address readiness, store-data readiness, wrong-tag rejection, load waiting behind an older unresolved store, store-at-ROB-commit behavior, load result commit behavior, x0 behavior, and report consistency.

## Phase 20 Integrated OOO Verification

Run `scripts/run_ooo_tests.ps1` to validate the integrated OOO experiment. The testbench requires at least 30 meaningful checks and currently covers dispatch, RS allocation, LSQ allocation, ROB stalls, CDB wakeup, out-of-order issue, in-order commit, stale tag handling, x0 suppression, conservative memory ordering, and report/trace generation.

## Phase 21 Final Integrated CPU Verification

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_tests.ps1
```

The runner checks that the final CPU top does not expose debug/scoreboard-only public ports, optionally runs Phase 20 OOO and Phase 15 SMT reference regressions, compiles the product-top testbench with Icarus `-g2012`, and requires a clear PASS plus at least 60 executed checks.

The UVM-inspired testbench drives only product instruction/data memory buses. Commit, ROB/RS/LSQ, branch-predictor, cache, and UCP observations are made hierarchically by monitors, not by adding product IO.
