# AGENTS.md

Instructions for Codex or any coding agent working in this repository.

This file is the repo-level operating manual. Read it before making changes. For deeper roadmap context, also read `docs/codex_long_term_instructions.md`.

## Project Mission

- Build a Windows-native, open-source RISC-V RTL portfolio project for front-end SoC practice.
- Grow the project in small verified phases from a minimal single-cycle RV32I subset toward a documented pipelined CPU.
- Prioritize readable RTL, repeatable verification, waveform/debug workflow, synthesis sanity checks, and resume-quality explanations.

## Current Workflow Rules

- Use Windows-native tools only. Do not assume WSL, Ubuntu, `/mnt/...` paths, or Linux package managers.
- Use PowerShell scripts in `scripts/` as the source-of-truth workflow.
- Keep `Makefile` targets as optional wrappers around PowerShell scripts.
- Prefer OSS CAD Suite for Windows for `iverilog`, `vvp`, `verilator`, `yosys`, and `gtkwave`.
- Do not add network-dependent install/build steps unless the user explicitly asks.
- Do not use proprietary EDA tools or vendor-specific IP.

Prohibited tools and flows include Synopsys, Cadence, Siemens, Questa, VCS, Xcelium, Design Compiler, Vivado, proprietary FPGA IP, and vendor-only simulation/synthesis flows.

## Phase Discipline

- Keep changes scoped to the phase the user asked for.
- Do not jump ahead to hazards, forwarding, gshare, cache, formal, UVM, or FPGA work unless explicitly requested. Phase 11 cache work is now limited to the documented D-cache experiment unless the user approves more.
- Before implementing a new phase, inspect the existing RTL, tests, scripts, and docs.
- Preserve working behavior from all completed phases while adding future features.
- If tools are missing, document the blocker clearly rather than pretending checks passed.

Expected long-term order:

1. Phase 0: Windows-native repo, scripts, docs, reports, and repeatable workflow.
2. Phase 1: Single-cycle subset with `ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`.
3. Phase 2: Single-cycle word memory and basic branches: `LW`, `SW`, `BEQ`, `BNE`.
4. Phase 3: Single-cycle jumps and upper immediates: `JAL`, `JALR`, `LUI`, `AUIPC`.
5. Phase 4: Baseline five-stage pipeline while preserving the single-cycle reference.
6. Phase 5: Pipeline trace logging, directed tests, and deterministic randomized tests.
7. Phase 6: Simple conditional branch prediction baseline, counters, and reports.
8. Phase 7: Gshare branch prediction comparison.
9. Phase 8: Synthesis-oriented reports and critical-path-style analysis.
10. Phase 9: Performance counters and benchmark-style reporting.
11. Phase 10: Configurable memory latency and memory-stall reporting.
12. Phase 10.5: SystemVerilog migration and coding-standard cleanup.
13. Phase 11: Small direct-mapped D-cache experiment with cache hit/miss counters and benchmark reports.
14. Phase 12: Simplified L1/L2-style D-cache hierarchy experiment with per-level counters.
15. Phase 13: Simplified UCP-style shared-cache partitioning experiment when approved.
16. Phase 15: Separate SMT-style thread-tagged in-order pipeline experiment.
17. Phase 16: Standalone scoreboard and reservation-station preparation layer.
18. Phase 17: Standalone Tomasulo-style dynamic scheduling experiment with reservation stations, tags, and CDB-style wakeup.

## RTL Style Rules

- Primary HDL language is now SystemVerilog.
- Preferred source extension is `.sv` for RTL and testbench files.
- Use open-source-tool-compatible SystemVerilog only.
- Use `logic` instead of legacy `reg`/`wire` where practical.
- Use `always_ff` for sequential logic and nonblocking assignments.
- Use `always_comb` for combinational logic and blocking assignments.
- Use explicit continuous `assign` statements for derived signals; do not convert Verilog net declaration assignments into `logic` initializations.
- Avoid UVM, SystemVerilog classes, interfaces, modports, DPI, complex packages, and advanced assertions unless explicitly requested.
- Keep modules small, explicit, and easy to review.
- Keep architectural register `x0` hardwired to zero.
- Separate synthesizable RTL under `rtl/` from testbench-only code under `tb/`.
- Preserve module interfaces and architectural behavior during refactors unless the phase explicitly allows interface changes.
- Keep generated outputs in `sim/` or `reports/`, not in source directories.
- Read `docs/systemverilog_style_guide.md` before adding or refactoring RTL.

## Verification Rules

- Every new instruction or datapath feature must include at least one directed test.
- Every memory or control-flow feature must include a test that would fail if the feature were missing.
- Simulations must print a clear `PASS` or `FAIL`.
- Preserve VCD waveform generation for debug.
- Keep Verilator lint and Yosys synthesis sanity checks in the normal workflow.
- Randomized assembly tests and reference-model checks now exist for Phase 5; keep them deterministic and hazard-free until hazard handling is implemented.
- Branch prediction infrastructure now includes Phase 6 simple mode and Phase 7 gshare mode; preserve both when extending predictor experiments.
- Phase 8 synthesis wrappers and reports are analysis infrastructure only; do not change CPU behavior just to improve reported numbers without explicit approval.
- Phase 9 benchmark reports are simulation-level microbenchmarks; do not describe them as industry-standard benchmark scores or silicon-accurate CPI.
- Phase 10 memory-latency reports are controlled memory-stall experiments, not cache hierarchy or DRAM timing models.
- Phase 10.5 migrated source to SystemVerilog; future scripts should use `.sv`, Icarus `-g2012`, and Yosys `read_verilog -sv`.
- Phase 11 adds a simplified direct-mapped D-cache only. Do not describe it as cache coherence or realistic DRAM.
- Phase 12 adds a simplified L1/L2-style D-cache hierarchy experiment. Do not describe it as a production hierarchy, coherent cache subsystem, or industrial memory signoff.
- Phase 15 adds a separate SMT-style experimental pipeline. Preserve the original single-thread pipeline, carry `thread_id` through new SMT pipeline metadata, and keep claims limited to in-order thread tagging rather than full SMT, Tomasulo, ROB, register renaming, or out-of-order execution.
- Phase 16 adds standalone readiness-model RTL. Preserve the working CPU paths, keep dependency state thread-aware, and do not claim full Tomasulo, register renaming, ROB support, speculative commit, or out-of-order execution.
- Phase 17 adds a standalone Tomasulo-style experiment. Keep it separate from the proven CPU pipelines, preserve thread-aware tags, require self-checking tests, and do not claim a full OOO core, ROB, LSQ, physical-register free list, speculative commit, or production Tomasulo backend.

## Documentation Rules

Update docs whenever architecture, supported instructions, workflow, limitations, or verification behavior changes.

Maintain at minimum:

- `README.md` for project overview and quickstart.
- `docs/phase0_setup.md` for Windows-native setup.
- `docs/phase1_single_cycle_subset.md` or later phase docs for architecture notes.
- `docs/debug_workflow.md` for simulation/waveform/debug commands.
- `docs/resume_notes.md` for portfolio framing.
- `docs/codex_long_term_instructions.md` for long-term roadmap and agent guidance.

Documentation should explain what was built, how it was verified, what is intentionally missing, and how it maps to front-end SoC skills.

## Before Making Changes

1. Read this file and `docs/codex_long_term_instructions.md`.
2. Check the current supported instruction list and phase docs.
3. Inspect existing scripts before adding new workflow commands.
4. Run available checks if the required tools are installed.
5. Keep edits small, phase-scoped, and documented.

## Definition Of Done

A change is complete only when:

- RTL builds, or the missing-tool blocker is documented.
- Tests exist for new behavior, or the lack of test is explicitly justified.
- Simulation has clear `PASS`/`FAIL` behavior.
- Lint and synthesis sanity checks are run when tools are available.
- Docs reflect the new behavior and known limitations.
- Generated artifacts remain out of source folders.









## Phase 21 Final Target Guidance

The final integrated target is `rtl/rv32i_final_cpu_top.sv`. Keep its public interface product-like: clock/reset plus instruction/data memory buses only. Do not add debug-only, scoreboard-only, trace, ROB, RS, LSQ, cache, UCP, or performance-counter output ports to the final top. Verification should observe final-core internals through testbench hierarchy and monitor/checker code.

Continue to keep advanced verification OSS-compatible. UVM-inspired structure is allowed, but do not add `uvm_pkg`, classes, DPI, vendor libraries, or proprietary simulator requirements unless the user explicitly changes the project direction.
