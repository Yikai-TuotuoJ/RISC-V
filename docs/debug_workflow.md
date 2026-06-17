# Debug Workflow

Run simulation and generate a waveform:

```powershell
.\scripts\run_wave.ps1
```

Open the waveform:

```powershell
.\scripts\view_wave.ps1
```

Important signals:

- `pc_dbg`
- `instr_dbg`
- `illegal_instr_dbg`
- `dut.u_regfile.regs`
- ALU inputs and output inside `dut.u_alu`

If GTKWave is unavailable, inspect the simulator console output first. The VCD file is still generated at `sim\phase1_basic.vcd` when Icarus Verilog is installed.

## Phase 5 Trace Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase5_trace.ps1
```

Inspect `reports\sim\pipeline_trace.log` and `reports\phase5_pipeline_trace.csv` for cycle-by-cycle IF/ID/EX/MEM/WB state. Open `sim\phase5_pipeline_trace.vcd` with GTKWave to correlate the CSV with waveform signals.

Useful trace columns include `ex_pc`, `ex_instr`, `wb_rd`, `wb_wdata`, `stall`, `flush`, `redirect`, and `redirect_target`.


## Curated Pipeline Waveform

Open the Phase 5 pipeline waveform with a pre-filtered signal set:

```powershell
gtkwave sim\phase5_pipeline_trace.vcd reports\sim\phase5_pipeline_structure.gtkw
```

The grouped view shows pipeline stage PCs/instructions, decoder control, ALU operands/result, memory access, writeback, and branch/jump redirect signals.

## Phase 6 Branch Prediction Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1 -SkipRegression
```

Inspect:

- `reports\sim\branch_prediction_trace.log`
- `reports\sim\branch_prediction_report.log`
- `sim\phase6_branch_predictor.vcd`

The trace includes a `BP:` line each cycle with predicted direction, predicted target, actual direction, actual target, and misprediction status. In the waveform, useful signals include `trace_bp_pred_taken`, `trace_bp_pred_target`, `trace_bp_actual_taken`, `trace_bp_actual_target`, `trace_bp_mispredict`, `trace_flush`, `trace_redirect`, and `trace_redirect_target`.

Open the curated Phase 6 waveform view with:

```powershell
gtkwave sim\phase6_branch_predictor.vcd reports\sim\phase6_branch_prediction.gtkw
```

## Phase 7 Gshare Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_gshare_tests.ps1 -SkipRegression
```

Inspect:

- `reports\sim\gshare_branch_prediction_trace.log`
- `reports\sim\gshare_branch_prediction_report.log`
- `sim\phase7_gshare.vcd`

The gshare trace line includes mode, resolved PC, GHR, PHT index, predicted direction, actual direction, and misprediction status.

Open the curated gshare waveform view with:

```powershell
gtkwave sim\phase7_gshare.vcd reports\sim\phase7_gshare.gtkw
```

## Phase 8 Synthesis Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_synth_reports.ps1
```

Inspect `reports\synth\synth_summary.md` first, then drill into the per-variant Yosys logs under `reports\synth\`. Yosys `check` results are structural sanity checks; they are not simulation, formal proof, or signoff timing.

## Phase 9 Performance Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_benchmarks.ps1
```

Inspect `reports\perf\benchmark_summary.md` for the table view and `reports\perf\benchmark_logs\` for per-run simulator output. Each completed run emits a structured `PERF:` line with cycles, retired instructions, CPI, flushes, branch counts, mispredictions, loads, and stores.

The benchmark waveform is `sim\phase9_benchmark.vcd`.

## VS Code Waveform Options

Recommended VS Code waveform extensions include WaveTrace, VaporView, and Surfer. Open `sim\phase5_pipeline_trace.vcd` directly in VS Code for a native viewer, or run the VS Code task `RISC-V: Open GTKWave Curated View` for the curated signal grouping.

## Phase 10 Memory Latency Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_memory_latency_tests.ps1 -SkipRegression
```

Inspect `reports\perf\memory_latency_summary.md` first, then per-run logs under `reports\perf\memory_latency_logs\`. Each completed run emits a `MEMPERF:` line with cycles, retired instructions, CPI, total stalls, memory stalls, load stalls, store stalls, loads, and stores.

The waveform is `sim\phase10_memory_latency.vcd`. Useful signals include `trace_stall`, `trace_mem_valid`, `trace_mem_pc`, `trace_wb_valid`, `trace_wb_pc`, `perf_mem_stall_count`, `perf_load_stall_count`, and `perf_store_stall_count`.

## Phase 10.5 SystemVerilog Debug

Source files now use `.sv`. If a simulation breaks after an HDL refactor, first check for SystemVerilog migration traps such as converting a continuous net declaration assignment into a one-time `logic` initialization. Use explicit `assign` statements for continuously derived signals.

Icarus commands should use `-g2012`; Yosys scripts should use `read_verilog -sv`.

## Phase 11 Cache Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_tests.ps1 -SkipRegression
```

Inspect:

- `reports\perf\cache_summary.md`
- `reports\perf\cache_logs\`
- `reports\sim\cache_trace.log`
- `sim\phase11_cache.vcd`

Useful waveform signals include `trace_dcache_access`, `trace_dcache_load`, `trace_dcache_store`, `trace_dcache_hit`, `trace_dcache_miss`, `trace_dcache_stall`, `trace_dcache_fill`, `trace_dcache_addr`, and the `perf_dcache_*` counters.

## Phase 12 Cache Hierarchy Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_hierarchy_tests.ps1 -SkipRegression -SkipPhase11
```

Inspect:

- `reports\perf\cache_hierarchy_summary.md`
- `reports\perf\cache_hierarchy_logs\`
- `reports\sim\cache_hierarchy_trace.log`
- `sim\phase12_cache_hierarchy.vcd`

Useful signals include `trace_dcache_hit`, `trace_dcache_miss`, `trace_l2_access`, `trace_l2_hit`, `trace_l2_miss`, `trace_backing_access`, `perf_l2_access_count`, `perf_l2_hit_count`, `perf_l2_miss_count`, and `perf_backing_access_count`.

## Phase 13 UCP-Style Partition Debug

Run the full Phase 13 flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

For fast policy-model-only debug:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1 -SkipRegression -SkipCacheHierarchy
```

Inspect:

- `reports\perf\ucp_partition_summary.md`
- `reports\perf\ucp_partition_summary.csv`
- `reports\perf\ucp_logs\`
- `tests\benchmarks\ucp\trace_*.txt`

Each log emits `UCPPERF:` lines. The model is trace-level, so use `estimated_penalty_cycles` for policy comparison and do not interpret it as pipeline CPI.

## Phase 13.5 RTL UCP Cache Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1 -SkipRegression -SkipCacheHierarchy
```

Inspect:

- `reports\perf\ucp_rtl_partition_summary.md`
- `reports\perf\ucp_rtl_logs\`
- `reports\sim\ucp_rtl_trace.log`
- `sim\phase13_5_ucp_cache.vcd`

The trace includes stream ID, L1/L2/L3 access and hit/miss events, backing-memory access, stall, fill, and cache hit level.

## Debugging Phase 14 UCP Validation

Use `reports/phase14_ucp/ucp_trace.log` to inspect stream selection, cache-level hits/misses, and active L3 allocation during the Phase 14 cache hierarchy tests. The trace is not a replacement for correctness checks; the pass/fail source of truth is `ucp_validation_summary.md` and the underlying simulation logs in `reports/phase14_ucp/logs/`.

## Phase 15 SMT Debug

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1 -SkipPriorRegressions
```

Inspect:

- `reports\sim\smt_trace.log`
- `reports\sim\smt_ucp_trace.log`
- `reports\perf\smt_summary.md`
- `reports\perf\smt_ucp_summary.md`
- `sim\phase15_smt.vcd`

Useful signals include stage valid bits, stage thread IDs, per-thread PC values, `trace_raw_stall`, `trace_mem_stall`, `trace_redirect_tid`, `trace_ucp_stream_id`, L1/L2/L3 hit/miss counters, and L3 allocation counters.

## Phase 16 Scoreboard Debug

Run the focused flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1 -SkipPriorRegressions
```

Inspect:

- `reports\sim\scoreboard_trace.log`
- `reports\perf\scoreboard_summary.md`
- `reports\perf\scoreboard_logs\scoreboard_validation.log`
- `sim\phase16_scoreboard.vcd`

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_synth.ps1
```

Useful RTL signals include `busy`, `busy_tag`, `entry_valid`, `entry_ready`,
`entry_src1_ready`, `entry_src2_ready`, `entry_src1_tag`, `entry_src2_tag`,
`broadcast_tid`, and `broadcast_tag`.

## Phase 17 Tomasulo Debug

Run the focused flow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1 -SkipPriorRegressions
```

Inspect:

- `reports\sim\tomasulo_trace.log`
- `reports\perf\tomasulo_summary.md`
- `reports\perf\tomasulo_logs\tomasulo_validation.log`
- `sim\phase17_tomasulo.vcd`

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_synth.ps1
```

Useful RTL signals include `rs_valid`, `rs_issued`, `rs_q1_ready`, `rs_q2_ready`, `rs_q1_tag`, `rs_q2_tag`, `rs_dst_tag`, `reg_busy`, `reg_tag`, `selected_found`, `older_waiting_found`, `cdb_fire`, `cdb_tag`, `wake_events`, and the `trace_*` outputs.

## Debugging Phase 18 ROB

Use `reports\sim\rob_trace.log` to inspect ROB activity. Important events are `DISPATCH`, `ISSUE`, `CDB`, `COMMIT_STALL`, and `COMMIT`. If a value appears on CDB but the architectural register is unchanged, that is expected until the matching ROB entry reaches the head and commits.

Use `sim\phase18_rob.vcd` for waveform inspection and `reports\perf\rob_summary.md` for counter-level validation.

## Phase 19 LSQ Debug Flow

Useful files:

- `reports/sim/lsq_trace.log` shows LSQ allocation, address wakeup, store data wakeup, load wait, load execute, store commit, and ROB commit events.
- `reports/perf/lsq_logs/lsq_validation.log` contains the self-checking simulation output.
- `sim/phase19_lsq.vcd` contains waveform data for the LSQ experiment.

Use the trace first to see program-order memory behavior, then inspect the VCD when signal-level timing matters.

## Phase 20 Integrated OOO Debug Flow

Useful Phase 20 outputs:

- `reports/sim/ooo_trace.log` for dispatch, issue, CDB, LSQ, memory-order, and commit events.
- `reports/perf/ooo_logs/ooo_validation.log` for all self-checking PASS/FAIL lines.
- `sim/phase20_ooo.vcd` for waveform inspection.

Start with `ooo_trace.log` to understand ordering, then open the VCD when signal timing matters.

## Phase 21 Final CPU Debug

Primary artifacts:

- `reports/sim/final_cpu_trace.log` for fetch, dispatch, issue, CDB, commit, recovery, cache, and UCP monitor events.
- `sim/final_cpu.vcd` for waveform debug.
- `reports/perf/final_cpu_summary.md` and `reports/perf/final_cpu_cache_ucp_summary.md` for summarized counters.

The final DUT has no debug-only output pins. During debug, inspect internal signals hierarchically from the testbench or waveform viewer.
