# RISC-V RTL Project

Windows-native open-source RISC-V RTL project for front-end SoC practice.

This repository starts with a minimal RV32I single-cycle CPU subset and is growing into a resume-level CPU project with simulation, lint, synthesis sanity checks, waveform debug, and documentation. Source RTL and testbenches now use open-source-tool-compatible SystemVerilog.

## Current Phase

- Phase 0: Windows-native repository and tool workflow.
- Phase 1: Minimal single-cycle RV32I subset CPU.
- Phase 2: Single-cycle memory and branch support.
- Phase 3: Single-cycle jump and upper-immediate support.
- Phase 4: Baseline 5-stage pipelined CPU, with the single-cycle core preserved as a reference.
- Phase 5: Pipeline trace logging, stronger directed checks, and deterministic randomized hazard-free tests.
- Phase 6: 1-bit conditional branch prediction baseline with counters, trace logging, and directed branch predictor tests.
- Phase 7: Gshare predictor with a 4-bit global history register, 16-entry 2-bit PHT, and same-program comparison against the simple predictor.
- Phase 8: Open-source Yosys synthesis reports comparing single-cycle, pipeline, and gshare pipeline wrappers.
- Phase 9: Simulation-level performance counters and microbenchmark-style CPI/branch reporting.
- Phase 10: Configurable data-memory latency, conservative RAW interlock stalls, and memory-latency benchmark reports.
- Phase 10.5: SystemVerilog source migration, `.sv` file convention, and future coding standard.
- Phase 11: Small direct-mapped D-cache experiment with hit/miss counters and cache benchmark reports.
- Phase 12: Simplified L1/L2-style D-cache hierarchy experiment with per-level reports.
- Phase 13: Simplified UCP-style shared-cache partitioning trace model with equal vs utility-guided policy reports.
- Phase 13.5: Pipeline-integrated RTL experiment with private logical L1 banks, shared L2, and UCP-partitioned L3.
- Phase 14: Active UCP validation and dynamic UCP stress/reporting.
- Phase 15: Separate SMT-style thread-tagged in-order pipeline experiment.
- Phase 16: Standalone scoreboard and reservation-station preparation layer.
- Phase 17: Standalone Tomasulo-style dynamic scheduling experiment with reservation stations, tags, and CDB-style wakeup.
- Phase 18: Constrained ROB / in-order commit experiment separating broadcast completion from architectural retirement.

## Supported Instructions

The current single-cycle reference core and Phase 4 pipeline baseline support:

- ADD
- SUB
- AND
- OR
- XOR
- ADDI
- LW
- SW
- BEQ
- BNE
- JAL
- JALR
- LUI
- AUIPC

Not included yet: full RV32I coverage, CSR, exceptions, interrupts, forwarding, I-cache, production cache hierarchy, UVM, SMT, multicore coherence, or formal verification. Phase 11 includes a small direct-mapped D-cache experiment, not a full cache hierarchy. The pipeline now has a conservative RAW interlock and memory-wait stalls, but not bypass forwarding.

## Toolchain

Use Windows-native open-source tools, preferably from OSS CAD Suite for Windows:

- iverilog
- vvp
- verilator
- yosys
- gtkwave
- git
- python, optional
- PowerShell

Run commands from PowerShell in the repository root. Icarus Verilog scripts use `-g2012`, and Yosys scripts use `read_verilog -sv` for source files.

This repo auto-detects OSS CAD Suite at `E:\shixi02\tools\oss-cad-suite` when running PowerShell scripts.

## Quick Commands

```powershell
.\scripts\check_tools.ps1
.\scripts\run_sim.ps1
.\scripts\run_phase2_sim.ps1
.\scripts\run_phase3_sim.ps1
.\scripts\run_phase4_sim.ps1
.\scripts\run_phase4_wave.ps1
.\scripts\run_phase4_lint.ps1
.\scripts\run_phase4_synth.ps1
.\scripts\run_phase5_trace.ps1
.\scripts\run_phase5_random.ps1
.\scripts\run_phase5_lint.ps1
.\scripts\run_phase5_synth.ps1
.\scripts\run_branch_predictor_tests.ps1
.\scripts\run_phase6_lint.ps1
.\scripts\run_phase6_synth.ps1
.\scripts\run_gshare_tests.ps1
.\scripts\run_phase7_lint.ps1
.\scripts\run_phase7_synth.ps1
.\scripts\run_synth_reports.ps1
.\\scripts\\run_benchmarks.ps1
.\\scripts\\run_ucp_tests.ps1
.\scripts\view_phase4_wave.ps1
.\scripts\clean.ps1
```

Use `powershell -ExecutionPolicy Bypass -File <script>` if the local PowerShell execution policy blocks direct script execution.

If GNU Make is installed, the Makefile wraps these scripts:

```powershell
make help
make sim
make phase2-sim
make phase3-sim
make phase4-sim
make phase4-wave
make phase4-lint
make phase4-synth
make phase5-trace
make phase5-random
make phase5-lint
make phase5-synth
make phase6-branch
make phase6-lint
make phase6-synth
make phase7-gshare
make phase7-lint
make phase7-synth
make synth-reports
make benchmarks
make ucp-tests
make clean
```

## Phase Notes

- Phase 1 simulation: `scripts\run_sim.ps1`
- Phase 2 simulation: `scripts\run_phase2_sim.ps1`
- Phase 3 simulation: `scripts\run_phase3_sim.ps1`
- Phase 4 pipeline simulation: `scripts\run_phase4_sim.ps1`

Phase 4 is a baseline pipeline only. The directed test is intentionally hazard-free and includes NOP spacing because forwarding and hazard detection are future work.

Phase 5 trace logging writes `reports\phase5_pipeline_trace.csv`, which records cycle-by-cycle IF/ID/EX/MEM/WB PCs, instructions, valid bits, writeback data, stall, flush, redirect, and redirect target.



## Phase 5 Verification

Run the aggregate Windows regression:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_pipeline_tests.ps1
```

The human-readable pipeline trace is written to `reports\sim\pipeline_trace.log`. The randomized generator is `scripts\gen_random_pipeline_test.py` and is run with the bundled OSS CAD Suite Python when available.

## Phase 6 Branch Prediction

Run the branch predictor regression:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1
```

Phase 6 implements a 16-entry 1-bit predictor for BEQ/BNE, indexed by `PC[5:2]`. Reports are written to `reports\sim\branch_prediction_report.log`, trace output to `reports\sim\branch_prediction_trace.log`, and the waveform to `sim\phase6_branch_predictor.vcd`.

## Phase 7 Gshare Prediction

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_gshare_tests.ps1
```

Phase 7 adds a 16-entry gshare predictor with a 4-bit GHR, 2-bit saturating counters, and index `branch_pc[5:2] XOR GHR`. Reports are written to `reports\sim\gshare_branch_prediction_report.log`, trace output to `reports\sim\gshare_branch_prediction_trace.log`, and the waveform to `sim\phase7_gshare.vcd`.

## Phase 8 Synthesis Reports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_synth_reports.ps1
```

Phase 8 generates Yosys synthesis sanity reports for single-cycle, pipeline/no-prediction, and pipeline/gshare wrappers. Summary files are written to `reports\synth\synth_summary.md` and `reports\synth\synth_summary.csv`. These reports are area/statistics-style comparisons, not industrial signoff timing.

## Phase 9 Benchmark Reports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\run_benchmarks.ps1
.\\scripts\\run_ucp_tests.ps1
```

Phase 9 runs controlled microbenchmarks across `none`, `simple`, and `gshare` predictor modes. Reports are written to `reports\perf\benchmark_summary.md` and `reports\perf\benchmark_summary.csv`. CPI is a simulation-level estimate, not a silicon performance claim.

## VS Code Workflow

This repo includes `.vscode` recommendations and tasks. In VS Code, run `Tasks: Run Task` and choose `RISC-V: Full Pipeline Regression` or `RISC-V: Open GTKWave Curated View`.

See `docs/vscode_workflow.md` for extension recommendations and waveform viewing options.

## Phase 10 Memory Latency Reports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_memory_latency_tests.ps1
```

Phase 10 runs memory-focused microbenchmarks at multiple `DMEM_LATENCY_CYCLES` settings. Reports are written to `reports\perf\memory_latency_summary.md` and `reports\perf\memory_latency_summary.csv`. This is a controlled simulation-level memory stall experiment.

## Phase 10.5 SystemVerilog Refactor

Source RTL and testbench files are now `.sv`. The project uses a conservative SystemVerilog subset for compatibility with Icarus Verilog, Verilator, and Yosys on Windows. Advanced methodology features such as UVM, classes, interfaces, DPI, and complex packages are intentionally avoided.

Future RTL should follow `docs/systemverilog_style_guide.md`.


## Phase 11 Cache Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_tests.ps1
```

Phase 11 adds a small direct-mapped D-cache experiment for the pipelined core. Reports are written to `reports\perf\cache_summary.md` and `reports\perf\cache_summary.csv`, detailed logs go under `reports\perf\cache_logs\`, and cache events are traced in `reports\sim\cache_trace.log`. This is a simplified cache-style RTL model, not a full cache hierarchy.

## Phase 12 Cache Hierarchy Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_cache_hierarchy_tests.ps1
```

Phase 12 adds a simplified L1/L2-style data-cache path for controlled cache hierarchy experiments. Reports are written to `reports\perf\cache_hierarchy_summary.md` and `reports\perf\cache_hierarchy_summary.csv`. This is still a simulation-level model, not a production cache hierarchy or coherence implementation.

## Phase 13 UCP-Style Partitioning

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

Phase 13 adds a trace-level simplified UCP-style shared-cache partitioning experiment. It compares static equal partitioning with a deterministic utility-guided allocation rule using logical workload traces under `tests\benchmarks\ucp\`. Reports are written to `reports\perf\ucp_partition_summary.md` and `reports\perf\ucp_partition_summary.csv`. The values are hit/miss and estimated miss-penalty metrics, not pipeline-integrated CPI or production cache QoS results.


## Phase 13.5 RTL UCP Cache Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1
```

Phase 13.5 adds a pipeline-integrated RTL cache hierarchy experiment: private logical L1 banks, shared unpartitioned L2, and UCP-style fixed partitioning at L3. Reports are written to `reports\perf\ucp_rtl_partition_summary.md` and `reports\perf\ucp_rtl_partition_summary.csv`. This is still an educational single-pipeline model, not multicore cache coherence or production cache QoS.

### Phase 13.6 Dynamic UCP

Phase 13.6 adds policy mode 2, a simplified dynamic UCP monitor for the L3 cache experiment. Run powershell -ExecutionPolicy Bypass -File .\scripts\run_ucp_tests.ps1 to compare static equal, fixed biased, and dynamic monitor policies. See docs\phase13_6_dynamic_ucp.md.


## Phase 14 Active UCP Validation

Phase 14 adds a serious validation/stress flow for the private-L1/shared-L2/UCP-L3 cache hierarchy. Run it with:

```powershell
.\scripts\run_phase14_ucp_validation.ps1
```

The flow compares L3 disabled, L3 unpartitioned, equal L3 partition, and fixed utility-guided L3 partition modes. Reports are generated under `reports/phase14_ucp/` as Markdown, CSV, and trace logs. This phase validates cache behavior and reporting; it does not add SMT, coherence, Tomasulo, out-of-order execution, or production UCP.

## Dynamic UCP Validation Update

Phase 14 now treats dynamic UCP as a primary validation mode, not merely a future idea. The added mode is:

```text
mode4_dynamic_ucp: L3 enabled, UCP enabled, dynamic monitor policy
```

The dynamic mode starts from the equal split, monitors L3 behavior, evaluates candidate allocations, and repartitions at interval boundaries. The validation checks that dynamic allocation remains legal, that each stream keeps at least one L3 line, that the allocation sum equals the total L3 line count, and that the pressure benchmark actually triggers repartitioning.

The fixed utility-guided policy remains only as a comparison point. It is useful for showing what an idealized deterministic allocation can look like, but it is not the main UCP claim.

## Long Dynamic UCP Benchmark Result

A longer benchmark, `dynamic_ucp_long_stream1`, was added to show a case where dynamic UCP can outperform equal partitioning. The program has two phases:

1. A warm-up/pressure phase that gives the dynamic monitor enough L3 accesses to repartition.
2. A longer stream-1 hot-set phase that repeatedly accesses five stream-1 cache lines.

With an equal 4/4 split, stream 1 cannot retain the five-line hot set as effectively. Dynamic UCP repartitions to 3/5 and gives stream 1 enough L3 capacity to improve reuse.

Observed result:

```text
equal partition:  cycles=502 L3 hits=16 backing accesses=20
dynamic UCP:      cycles=462 L3 hits=21 backing accesses=15 final alloc=3/5
fixed 6/2 policy: cycles=582 L3 hits=6  backing accesses=30
```

This is the right interview framing: dynamic UCP has overhead and may not win on short programs, but on a longer phase-changing workload it can adapt and outperform a static equal split or a fixed allocation biased toward the wrong stream.

## Phase 15 SMT-Style Thread Tagging

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1
```

For faster SMT-only iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_smt_tests.ps1 -SkipPriorRegressions
```

Phase 15 adds a separate experimental two-thread in-order pipeline, `rv32i_smt_pipeline_core.sv`, while preserving the original single-thread pipeline. Each logical thread has its own PC and architectural register state. Pipeline stages carry `thread_id`, and cache/UCP stream selection can use thread ID instead of the older address-derived stream approximation.

Reports are generated at `reports\perf\smt_summary.md`, `reports\perf\smt_summary.csv`, `reports\perf\smt_ucp_summary.md`, and `reports\perf\smt_ucp_summary.csv`. Traces are generated at `reports\sim\smt_trace.log` and `reports\sim\smt_ucp_trace.log`.

This is a simplified SMT-style experiment. It does not implement Tomasulo, register renaming, a ROB, superscalar issue, production SMT scheduling, multicore coherence, or full cache QoS.

## Phase 16 Scoreboard / Tomasulo Preparation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1
```

For faster standalone readiness-model iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_scoreboard_tests.ps1 -SkipPriorRegressions
```

Phase 16 adds a separate synthesizable scoreboard and reservation-station-like
readiness model. It tracks per-thread register busy state, producer tags,
operand readiness, thread-aware broadcast wakeups, and finite-entry stalls.
Reports are generated at `reports\perf\scoreboard_summary.md` and `.csv`, with a
trace at `reports\sim\scoreboard_trace.log`.

This is preparation for a later Tomasulo-style experiment. It does not add
out-of-order execution, a reorder buffer, register renaming, speculative commit,
or a load/store queue.

## Phase 17 Tomasulo-Style Dynamic Scheduling Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1
```

For faster standalone Tomasulo iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_tests.ps1 -SkipPriorRegressions
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_tomasulo_synth.ps1
```

Phase 17 adds a standalone Tomasulo-style scheduler experiment using four reservation-station entries, per-thread register-status tags, readiness-based ALU issue, CDB-style wakeup, stale-tag protection, and directed reports. It supports ADD, SUB, AND, OR, XOR, and ADDI in the experiment model.

Reports are generated at `reports\perf\tomasulo_summary.md` and `.csv`, with trace output at `reports\sim\tomasulo_trace.log` and waveform output at `sim\phase17_tomasulo.vcd`.

This phase demonstrates dynamic scheduling mechanisms. It does not implement a full out-of-order CPU, ROB, physical-register free list, precise retirement, LSQ, branch speculation, or production Tomasulo backend.
## Phase 18 ROB / In-Order Commit Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_tests.ps1
```

For faster standalone ROB iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_tests.ps1 -SkipPriorRegressions
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_rob_synth.ps1
```

Phase 18 adds a standalone constrained ROB experiment. CDB-style broadcast marks ROB entries ready and wakes dependents, while architectural registers update only when the ROB head commits in program order. Reports are generated at `reports\perf\rob_summary.md` and `.csv`, with trace output at `reports\sim\rob_trace.log` and waveform output at `sim\phase18_rob.vcd`.

This phase demonstrates ROB allocation, completion, in-order commit, stale-tag protection, x0 commit suppression, and younger-completed-waiting behavior. It does not implement a full OOO backend, LSQ, precise exception recovery, branch speculation, or production memory disambiguation.

## Phase 19 Limited LSQ Preparation Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_tests.ps1
```

For faster standalone LSQ iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_tests.ps1 -SkipPriorRegressions
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_lsq_synth.ps1
```

Phase 19 adds a standalone limited load/store queue preparation experiment. It tracks memory uop allocation, address readiness, store-data readiness, conservative load ordering behind older unresolved stores, and store commit through the ROB. Reports are generated at `reports\perf\lsq_summary.md` and `.csv`, with trace output at `reports\sim\lsq_trace.log` and waveform output at `sim\phase19_lsq.vcd`.

This phase does not implement full speculative memory execution, store-to-load forwarding, memory disambiguation, violation replay, precise exception recovery, or production OOO memory behavior.

## Phase 20 Integrated OOO Experiment

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_tests.ps1
```

Focused iteration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_tests.ps1 -SkipPriorRegressions
```

Focused structural checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_ooo_synth.ps1
```

Phase 20 adds `rtl\ooo_experiment_core.sv`, a final integrated OOO-concept core combining reservation stations, CDB wakeup, register-status tags, ROB in-order commit, and a limited LSQ. Reports are generated at `reports\perf\ooo_summary.md` and `.csv`, with trace output at `reports\sim\ooo_trace.log` and waveform output at `sim\phase20_ooo.vcd`.

## Phase 21 Final Integrated CPU Target

Phase 21 adds `rtl/rv32i_final_cpu_top.sv`, a product-like integrated target with only clock/reset and instruction/data memory bus ports. Debug-only and scoreboard-only DUT pins are intentionally excluded; the self-checking testbench observes internal ROB/RS/LSQ, predictor, cache, and UCP state through hierarchy.

Run the final flow with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_synth.ps1
```

This remains an educational open-source RTL integration, not a production OOO processor or full UVM environment.
