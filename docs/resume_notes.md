# Resume Notes

This project is designed to grow into a resume-level RTL CPU project.

Phase 1 resume phrasing:

- Implemented a Verilog RV32I single-cycle CPU subset supporting ADD, SUB, AND, OR, XOR, and ADDI.
- Built directed instruction-level tests with self-checking simulation and waveform generation.
- Added open-source RTL workflow using Icarus Verilog, Verilator lint, and Yosys synthesis sanity checks.
- Documented design limitations and staged roadmap toward pipelining, hazards, forwarding, branches, randomized testing, and FPGA-oriented checks.

Future resume value comes from expanding the ISA subset, adding a five-stage pipeline, demonstrating hazard handling, and maintaining reports from repeatable open-source checks.

Phase 2 resume phrasing:

- Extended the single-cycle RV32I subset with word-aligned LW/SW data memory support and BEQ/BNE control flow.
- Added directed tests covering memory write/readback, taken and not-taken branch paths, preserved ALU behavior, and x0 hardwiring.
- Maintained open-source verification using Icarus Verilog simulation, Verilator lint, Yosys synthesis sanity, and VCD waveform generation.

Phase 3 resume phrasing:

- Extended the single-cycle RV32I subset with JAL, JALR, LUI, and AUIPC control-flow and PC-relative datapath support.
- Added directed tests for jump target selection, link register writes, upper-immediate writeback, AUIPC PC-relative behavior, and x0 hardwiring.

Phase 4 resume phrasing:

- Added a separate baseline 5-stage RV32I pipeline with IF, ID, EX, MEM, and WB stages while preserving the single-cycle core as a reference model.
- Implemented pipeline registers, control-signal propagation, WB-stage register writes, and EX-stage branch/jump redirects with younger-instruction flush.
- Built a hazard-free directed pipeline test with explicit NOP spacing, waveform generation, Verilator lint, and Yosys synthesis sanity checks.
- Documented current pipeline limitations and the next roadmap step: RAW hazard detection, forwarding, and load-use stalls.

Phase 5 resume phrasing:

- Added cycle-by-cycle pipeline trace visibility for IF, ID, EX, MEM, and WB stages, including writeback data and branch/jump redirect information.
- Built a CSV trace logging workflow and waveform flow for debugging pipeline execution.
- Added deterministic hazard-free randomized instruction generation with a lightweight reference model for final register and memory comparison.
- Strengthened open-source regression coverage using Icarus Verilog simulation, Verilator lint, and Yosys synthesis sanity checks.

Phase 6 resume phrasing:

- Added a 16-entry 1-bit conditional branch predictor to a 5-stage RV32I pipeline, indexed by `PC[5:2]` and updated on EX-stage branch resolution.
- Implemented misprediction detection, redirect, valid-bit flushing, and wrong-path commit prevention for BEQ/BNE control hazards.
- Added branch prediction counters for resolved branches, predicted/actual direction, correct predictions, mispredictions, and accuracy reporting.
- Built directed branch-prediction tests and trace/report generation using a Windows-native open-source RTL workflow.

Phase 7 resume phrasing:

- Upgraded the pipelined RV32I branch predictor to a gshare design with a 4-bit global history register and 16-entry 2-bit saturating pattern history table.
- Implemented selectable branch predictor modes for no prediction, simple one-bit prediction, and gshare prediction.
- Added gshare-specific trace logging for GHR, PHT index, predicted direction, actual branch outcome, and misprediction status.
- Built branch-heavy directed tests with same-program comparison between gshare and the simple predictor, documenting accuracy tradeoffs rather than overclaiming.

Phase 8 resume phrasing:

- Built a reproducible Windows-native Yosys synthesis-reporting flow for single-cycle and pipelined RV32I RTL variants.
- Generated area/statistics-style reports, synthesized netlists, and JSON outputs for single-cycle, no-prediction pipeline, and gshare pipeline wrappers.
- Compared generic cell-count trends and documented likely critical datapath regions in decode, ALU, branch-control, writeback, and branch-prediction paths.
- Framed synthesis results honestly as open-source sanity checks rather than industrial signoff timing.

Phase 9 resume phrasing:

- Added simulation-level performance counters for cycles, retired instructions, CPI, flushes, branches, mispredictions, loads, and stores.
- Built controlled microbenchmark-style programs to compare pipeline behavior across no-prediction, simple-predictor, and gshare predictor modes.
- Generated reproducible Markdown/CSV benchmark reports using a Windows PowerShell and Python flow.
- Used benchmark reports to reason about control-hazard behavior and predictor-mode tradeoffs without claiming silicon-level performance signoff.

Phase 10 resume phrasing:

- Added a configurable data-memory latency model to evaluate pipelined load/store stall behavior under delayed memory responses.
- Implemented a conservative RAW interlock so dependent instructions wait for in-flight producers, including delayed-load cases.
- Extended simulation-level counters and reports with memory stalls, load stalls, store stalls, CPI impact, and load/store counts.
- Built memory-focused microbenchmarks and reproducible Markdown/CSV reports using a Windows-native open-source RTL flow.

Avoid claiming a production cache hierarchy, realistic DRAM timing, or silicon-level memory performance. Phase 10 is a controlled educational memory-stall experiment.

Phase 10.5 resume phrasing:

- Refactored RTL and verification collateral into an open-source-tool-compatible SystemVerilog codebase.
- Standardized RTL style around `.sv` files, `logic`, `always_ff`, and `always_comb` while preserving behavior.
- Updated Windows PowerShell, Icarus, Verilator, and Yosys flows for SystemVerilog-compatible simulation, lint, and synthesis checks.
- Documented a SystemVerilog coding standard for future RTL development without overclaiming UVM or proprietary methodology.

Avoid claiming a full UVM environment, advanced SystemVerilog verification methodology, or proprietary EDA flow.

Phase 11 resume phrasing:

- Added a small direct-mapped D-cache experiment with valid/tag/data arrays, write-through/write-allocate store behavior, configurable miss penalty, and hit/miss counters.
- Extended the pipelined CPU performance flow with cache-enabled vs cache-disabled microbenchmark reports.
- Built cache-focused tests for repeated loads, store/load correctness, conflict behavior, and mixed memory/ALU sequences.
- Documented cache limitations honestly as a simplified educational RTL model, not a full cache hierarchy or signoff memory subsystem.

Avoid claiming cache coherence, multi-level hierarchy, realistic DRAM timing, or industrial cache verification.

Phase 12 resume phrasing:

- Extended the cache experiment into a simplified L1/L2-style data-cache hierarchy with per-level hit/miss counters.
- Built cache hierarchy microbenchmarks that expose L1 hits, L1 conflict misses, L2 hits, L2 misses, and backing-memory accesses.
- Generated reproducible Markdown/CSV reports comparing CPI and hit-rate behavior across disabled, L1-only, and L1+L2 modes.
- Documented the model as a controlled educational experiment preparing for later shared-cache partitioning work.

Avoid claiming production cache hierarchy, cache coherence, realistic DRAM modeling, or industrial memory-system signoff.

Phase 13 resume phrasing:

- Added a simplified UCP-style shared-cache partitioning experiment comparing static equal partitioning with utility-guided allocation.
- Built deterministic cache-utility traces to study hit-rate and estimated miss-penalty effects under different shared-cache allocations.
- Generated reproducible Markdown/CSV reports for cache partitioning policy comparisons.
- Documented the model as a trace-level educational approximation, not a production cache QoS controller or multicore coherence implementation.

Avoid claiming full UCP, multicore cache QoS, cache coherence, or industrial shared-cache partition control.

Phase 13.5 resume phrasing:

- Extended the cache experiment into a pipeline-integrated RTL hierarchy with private logical L1 banks, shared L2, and a UCP-style partitioned L3.
- Added address-derived logical stream IDs to study cache partitioning before implementing SMT or multicore support.
- Built directed stress tests and Markdown/CSV reports comparing equal and utility-guided fixed L3 partitioning.
- Documented the design honestly as an educational RTL cache-management experiment, not production UCP, multicore QoS, or cache coherence.

Avoid claiming dynamic UCP, hardware thread scheduling, multicore execution, cache coherence, or industrial shared-cache QoS.

## Phase 13.6 Dynamic UCP Notes

- Added a simplified dynamic UCP RTL monitor using shadow tags and exhaustive two-stream L3 partition selection.
- Compared static equal, fixed biased, and dynamic monitor partition policies with reproducible reports.
- Documented that repartition invalidation is correctness-friendly but can hurt short benchmark CPI, avoiding overclaiming production UCP behavior.


## Phase 14 Resume Notes

- Built a detailed validation suite for a simplified UCP-style cache hierarchy with private L1 banks, shared L2, and UCP-partitioned L3.
- Verified policy-dependent L3 allocation, per-stream counters, cache-level hit/miss behavior, and counter consistency using directed RTL simulations.
- Generated reproducible Markdown/CSV reports comparing L3 disabled, L3 unpartitioned, equal partition, and fixed utility-guided partition modes.
- Documented why the model uses address-derived logical streams and how it differs from production multicore UCP, cache QoS, and coherence.

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

## Phase 15 Resume Notes

- Added a simplified SMT-style thread-tagging experiment with a separate two-thread in-order pipeline, per-thread PC state, and per-thread architectural register banks.
- Carried thread IDs through IF/ID, ID/EX, EX/MEM, and MEM/WB so hazards, writeback, branch redirect, traces, and counters are thread-aware.
- Connected pipeline thread IDs to the existing cache/UCP stream model, while preserving the legacy address-derived stream mode for earlier experiments.
- Built directed SMT tests and reports covering cross-thread register isolation, load/store behavior, branch/jump redirect, cache/UCP stream mapping, and counter consistency.

Avoid claiming full SMT, out-of-order execution, register renaming, ROB support, superscalar scheduling, cache coherence, or production cache QoS.

## Phase 16 Resume Notes

- Added a simplified scoreboard and reservation-station preparation layer to model instruction readiness, dependency tracking, and result wakeup behavior.
- Implemented thread-aware register busy tracking and producer tags so the same architectural register number in different SMT contexts remains independent.
- Built directed validation for x0 handling, operand waits, matching-tag broadcast wakeup, wrong-thread rejection, multi-entry wakeup, and scoreboard-capacity stalls.
- Documented how the preparation layer differs from full Tomasulo, ROB-based retirement, register renaming, and complete out-of-order execution.

Avoid claiming full Tomasulo, out-of-order execution, a reorder buffer, physical-register renaming, speculative commit, or a load/store queue.

## Phase 17 Resume Notes

- Added a standalone Tomasulo-style dynamic scheduling experiment with reservation stations, producer tags, readiness-based ALU issue, and CDB-style broadcast wakeup.
- Demonstrated younger-ready-before-older-waiting issue, matching-tag operand wakeup, stale-tag write protection, and thread-aware dependency isolation.
- Built a self-checking validation suite with 52 explicit checks plus Markdown/CSV reports, trace logging, waveform generation, Verilator lint, and Yosys synthesis sanity.
- Documented the distinction between this scheduling experiment and a full out-of-order CPU with ROB, physical-register renaming, LSQ, precise retirement, and speculation recovery.

Avoid claiming full Tomasulo, complete out-of-order execution, precise ROB commit, load/store queue support, physical-register free-list management, or production OOO backend design.

## Phase 18 Resume Notes

Good wording:

- Added a constrained ROB experiment to separate Tomasulo-style execution completion from in-order architectural commit.
- Implemented ROB tags, head-based commit, stale-tag protection, x0 commit suppression, and tests showing younger completed instructions waiting behind older incomplete instructions.
- Built directed validation and Markdown/CSV reports for ROB allocation, completion, commit stalls, and in-order architectural update.

Avoid wording:

- Implemented a full out-of-order CPU.
- Completed precise exception support.
- Implemented production ROB, LSQ, or branch speculation recovery.

## Phase 19 Resume Notes

Good wording:

- Added a limited load/store queue preparation experiment to model address readiness, store-data readiness, and conservative memory ordering.
- Connected memory uop completion to a constrained ROB model while keeping stores committed in program order.
- Built directed validation for LSQ allocation, LSQ full stalls, wrong-tag wakeup rejection, load waiting behind older unresolved stores, and store-at-commit behavior.
- Documented limitations versus full memory disambiguation, store-to-load forwarding, speculative replay, and production OOO memory execution.

Avoid wording:

- Implemented a full OOO memory subsystem.
- Completed speculative load/store execution.
- Implemented production memory disambiguation or replay.
- Implemented a cache-coherent OOO backend.

## Phase 20 Resume Notes

Good wording:

- Consolidated separate Tomasulo, ROB, and LSQ concept models into a final integrated OOO-style experimental core supporting a limited RV32I subset.
- Demonstrated readiness-based ALU issue, CDB wakeup, ROB in-order commit, and conservative load/store ordering through directed validation tests.
- Generated reports and traces for dispatch, issue, broadcast, wakeup, completion, commit, and memory-order events.
- Documented limitations versus production OOO processors, including lack of branch speculation, full memory disambiguation, precise exceptions, and complete physical register renaming.

Avoid wording:

- Implemented a full production out-of-order RISC-V CPU.
- Completed industrial Tomasulo CPU.
- Implemented full speculative OOO backend.
- Implemented precise exception handling or complete memory replay.

## Phase 21 Resume Notes

Good wording:

- Built a product-like integrated RTL CPU top with OOO-style backend concepts, SMT-style thread tagging, gshare branch prediction, LSQ memory ordering concepts, and a UCP-aware cache hierarchy.
- Refactored final verification away from debug-only DUT pins into an OSS-compatible SystemVerilog monitor/scoreboard environment.
- Verified the final target with 96 self-checking tests, trace logging, waveform generation, cache/UCP reports, Verilator lint, and Yosys synthesis sanity checks.
- Documented limitations versus production OOO CPUs, full UVM, precise exceptions, cache coherence, and physical-design signoff.

Avoid wording:

- Implemented a production OOO processor.
- Completed full industrial UVM verification.
- Implemented precise exceptions, full physical-register renaming, or cache coherence.
- Achieved timing closure or signoff-quality verification.
