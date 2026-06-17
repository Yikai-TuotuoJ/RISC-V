# Phase 21: Final Product-Like Integrated CPU Target

Phase 21 adds a final integrated RTL target, `rtl/rv32i_final_cpu_top.sv`, that combines the project concepts into one product-style top-level. Earlier experimental cores remain in the repository as references and regression baselines.

## Public Interface

The final top exposes only product-style ports:

- `clk`, `rst_n`
- instruction memory request/response bus
- data memory request/response bus

It intentionally does not expose scoreboard injection pins, debug register-write pins, CDB forcing pins, trace buses, ROB/RS/LSQ dump ports, or performance-counter output ports. Verification observes internal state hierarchically from the testbench.

## Integrated Features

The final target includes a compact educational integration of:

- two logical SMT threads with per-thread PCs and architectural register banks
- pipeline-carried thread metadata inside the core
- gshare branch predictor instance for conditional branch prediction
- internal ROB/RS/LSQ-style bookkeeping and CDB-style completion counters
- in-order architectural commit behavior in the validation flow
- load/store traffic through the product data-memory bus
- stores reaching the backing memory path only through the memory request path
- private L1 D-cache banks selected by thread ID
- shared two-way L2 structure using a one-bit pseudo-LRU policy
- shared four-way L3 structure using tree-style pseudo-LRU state
- dynamic L3 UCP-style allocation counters and repartition observations

This is still an educational RTL integration. It is not a production OOO core, does not implement precise exceptions, CSR, interrupts, coherence, superscalar issue, a full physical-register free list, or industrial memory replay.

## Verification Model

The Phase 21 testbench is `tb/tb_final_cpu_uvm_style.sv`. It is UVM-inspired but deliberately does not use `uvm_pkg`, classes, DPI, or proprietary simulator features. It contains:

- product instruction/data memory drivers
- monitor-style hierarchical observation of fetch, dispatch, issue, CDB, commit, recovery, cache, and UCP events
- self-checking architectural checks for two thread programs
- cache/UCP counter consistency checks
- report generation and VCD waveform generation

The final runner fails if fewer than 60 checks execute. The current validation executes 96 checks.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_lint.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run_final_cpu_synth.ps1
```

Use `-SkipPriorRegressions` with the test runner for focused Phase 21 iteration.

## Reports

Generated artifacts include:

- `reports/perf/final_cpu_summary.md`
- `reports/perf/final_cpu_summary.csv`
- `reports/perf/final_cpu_cache_ucp_summary.md`
- `reports/sim/final_cpu_trace.log`
- `sim/final_cpu.vcd`
- `reports/synth/final_cpu_yosys.log`

## Interview Framing

Good explanation:

> I consolidated the earlier single-purpose experiments into a product-style RTL top with only memory-bus ports. The verification environment moved debug visibility out of DUT IO and into hierarchical monitors, similar in spirit to UVM monitors and scoreboards but kept compatible with open-source simulators. The design demonstrates how SMT thread tags, branch prediction, ROB/RS/LSQ concepts, and cache/UCP policies interact, while the reports document what is simplified versus production OOO CPUs.

Do not claim full industrial UVM, production out-of-order execution, precise exception machinery, cache coherence, or signoff verification.
