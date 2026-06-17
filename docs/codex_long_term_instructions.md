# Codex Long-Term Instructions

This document is the long-term working guide for Codex or any future coding agent continuing this RISC-V RTL project.

## Project Identity

This is an open-source, Windows-native RISC-V RTL learning and portfolio project. The main audience is a front-end SoC or CPU RTL team evaluating practical design, verification, debug, and synthesis-sanity skills.

The project should grow gradually from a minimal single-cycle RV32I subset into a better documented CPU project with verification artifacts and resume-ready explanations.

## Tool Rules

- Use Windows-native tools. Do not assume WSL or Ubuntu.
- Prefer OSS CAD Suite for Windows for Icarus Verilog, Verilator, Yosys, and GTKWave.
- Use PowerShell scripts as the source-of-truth workflow.
- Keep Makefile targets as optional wrappers only.
- Do not use Synopsys, Cadence, Siemens, Questa, VCS, Xcelium, Design Compiler, Vivado, proprietary IP, or vendor-specific flows.
- Do not introduce network-dependent build steps unless the user explicitly asks.

## RTL Style Rules

- Prefer Verilog-2005-compatible RTL.
- Avoid UVM, SystemVerilog classes, interfaces, packages, DPI, and simulator-specific features.
- Keep modules small and readable.
- Use explicit signal names and simple combinational/sequential blocks.
- Keep x0 hardwired to zero in the architectural register file.
- Keep generated outputs in `sim/` and `reports/`.

## Verification Rules

- Every new instruction needs at least one directed test.
- Every new control-flow or memory feature needs a test that would fail if the feature were missing.
- Simulation must print a clear PASS/FAIL result.
- Preserve waveform generation for debug.
- Keep Verilator lint and Yosys synthesis sanity in the normal workflow.
- Randomized assembly tests can be added later, after the directed test base is stable.

## Documentation Rules

Update documentation whenever behavior changes. At minimum, maintain:

- setup instructions
- architecture notes
- debug workflow
- resume notes
- supported instruction list
- known limitations

Documentation should explain what was built, how it was verified, what is intentionally missing, and how the work maps to front-end SoC skills.

## Phase Roadmap

### Phase 0: Repository and Tool Workflow

Goal: create a clean Windows-native RTL project skeleton with repeatable scripts, docs, and reports folders.

Expected artifacts:

- README
- AGENTS.md
- PowerShell scripts
- optional Makefile wrappers
- docs folder
- reports folder
- sim folder

### Phase 1: Minimal Single-Cycle RV32I Subset

Goal: implement a tiny single-cycle CPU supporting ADD, SUB, AND, OR, XOR, and ADDI.

Expected artifacts:

- simple RTL modules
- directed hex test
- self-checking testbench
- waveform generation
- lint report
- synthesis sanity report
- docs update

### Phase 2: Memory and Basic Branches

Goal: extend the single-cycle core with word-aligned `LW`/`SW` data memory and `BEQ`/`BNE` branch behavior.

Expected artifacts:

- data memory implementation
- I/S/B immediate generation
- branch PC selection
- directed memory/branch test
- waveform generation
- lint report
- synthesis sanity report
- docs update

### Phase 3: Jump and Upper-Immediate Instructions

Goal: extend the single-cycle core with `JAL`, `JALR`, `LUI`, and `AUIPC`.

Expected artifacts:

- U-type immediate generation
- J-type immediate generation
- jump target PC selection
- link writeback path using `pc + 4`
- directed jump/upper-immediate test
- waveform generation
- lint report
- synthesis sanity report
- docs update

### Phase 4: Baseline 5-Stage Pipeline

Goal: add a separate IF/ID/EX/MEM/WB pipelined core while preserving the single-cycle core as a reference.

Expected work:

- pipeline registers
- control signal propagation
- WB path through MEM/WB
- EX-stage branch and jump redirect
- flush of younger instructions on taken redirect
- hazard-free directed pipeline tests with explicit NOP spacing
- compare expected architectural behavior against the single-cycle subset where possible

### Phase 5: Pipeline Verification, Trace Logging, and Randomized Tests

Goal: improve observability and verification quality without adding major CPU architecture features.

Expected work:

- cycle-by-cycle IF/ID/EX/MEM/WB trace visibility
- CSV trace logging from simulation
- stronger directed checks for redirects, writebacks, and x0 behavior
- deterministic hazard-free randomized instruction generation
- simple reference-model comparison for final registers and small memory windows
- documentation of trace and randomized-test limitations

### Phase 6: Branch Prediction Baseline

Add a simple conditional-branch prediction baseline before advanced predictor work.

Expected work:

- static not-taken baseline documentation and counters
- 1-bit PC-indexed predictor for BEQ/BNE
- misprediction detection and redirect
- wrong-path commit prevention checks
- branch prediction trace and report generation

### Phase 7: Gshare Branch Prediction

Upgrade the Phase 6 predictor to a gshare-style experiment.

Possible scope:

- global history register
- XOR of PC index and global history
- comparison against Phase 6 1-bit predictor
- branch-heavy tests and accuracy reporting

### Phase 8: Basic Synthesis-Oriented Reporting

Improve open-source synthesis reporting before adding more architecture features.

Expected work:

- improve Yosys synthesis scripts
- collect area/stat reports
- compare single-cycle, pipelined, and branch-predicted pipeline reports
- document critical-path-style observations from open-source reports

### Phase 9: Hazards and Forwarding

Add practical pipeline correctness features.

Expected work:

- RAW hazard detection
- EX/MEM and MEM/WB forwarding
- load-use stall after load support exists
- branch flush validation with fewer hand-inserted NOPs
- directed hazard tests

### Phase 10: Cache or Memory-Latency Model

Add a simple memory-system timing experiment.

Possible scope:

- configurable instruction/data memory latency
- pipeline stall behavior for memory wait states
- optional tiny direct-mapped instruction or data cache
- CPI impact reporting on load/store and mixed benchmarks

### Phase 11: Stronger Verification

Add broader test generation and reporting.

Possible scope:

- Python-generated directed/random assembly
- reference-model comparison for supported instructions
- regression script
- report summaries

### Phase 12: FPGA-Oriented and Synthesis Sanity

Stay open-source unless the user changes constraints.

Possible scope:

- deeper Yosys synthesis reports
- resource trend documentation
- optional open FPGA flow only if suitable hardware/tooling is chosen later

## Before Making Changes

1. Read README, AGENTS.md, and this file.
2. Check current supported instruction list.
3. Run available tests if tools are installed.
4. Keep changes phase-scoped.
5. Update docs and tests with behavior changes.

## Definition of Done for Future Codex Work

A change is not complete until:

- RTL builds or the missing tool blocker is documented.
- Tests exist or the lack of test is explicitly justified.
- PASS/FAIL behavior is clear.
- Docs reflect the new behavior.
- Generated artifacts are kept out of source folders.




