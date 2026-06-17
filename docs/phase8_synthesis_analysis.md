# Phase 8: Synthesis-Oriented Reporting and Critical-Path-Style Analysis

Phase 8 adds a reproducible open-source synthesis reporting flow around the existing RTL. It does not add new CPU architecture features.

## What Was Synthesized

Three synthesis wrapper tops were added:

- `top_single_cycle`: preserved single-cycle core
- `top_pipeline`: 5-stage pipeline with branch prediction disabled through `BP_MODE=0`
- `top_pipeline_gshare`: 5-stage pipeline with gshare enabled through `BP_MODE=2`

The wrappers avoid duplicating CPU logic and exist only to make synthesis comparisons repeatable.

## Tools Used

The flow uses Windows-native OSS CAD Suite tools:

- Yosys
- ABC through Yosys, when available
- PowerShell
- Python for report parsing

These reports are synthesis sanity checks and area/statistics-style comparisons. They are not industrial timing signoff and should not be described as timing closure.

## Generated Reports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_synth_reports.ps1
```

Outputs:

- `reports/synth/single_cycle_yosys.log`
- `reports/synth/pipeline_yosys.log`
- `reports/synth/pipeline_gshare_yosys.log`
- `reports/synth/synth_summary.md`
- `reports/synth/synth_summary.csv`
- `reports/synth/netlists/`
- `reports/synth/json/`

## Current Comparison

Current summary from `reports/synth/synth_summary.md`:

| Variant | Cells | Wire Bits | DFF Cells | Mux Cells | Yosys Check |
|---|---:|---:|---:|---:|---:|
| Single-cycle | 25143 | 26129 | 9216 | 8381 | 0 problems |
| Pipeline, no prediction | 27372 | 29481 | 10214 | 8415 | 0 problems |
| Pipeline, gshare | 27644 | 29854 | 10248 | 8446 | 0 problems |

In this generic Yosys/ABC mapping, the pipeline/no-prediction wrapper reports 2229 more cells than the single-cycle wrapper. The gshare wrapper reports 272 more cells than the no-prediction pipeline wrapper.

These numbers include the simple simulation memories and exposed debug/reporting outputs, so they should be interpreted as trend data rather than final implementation area.

## Critical-Path-Style Observations

This flow does not produce signoff timing, but the RTL structure suggests likely long combinational regions:

- Single-cycle core: PC to instruction decode to register-file read to ALU/branch decision to next-PC selection.
- Decode/control: opcode/funct decode fans out into ALU select, immediate select, writeback select, memory write, branch, and jump controls.
- ALU/branch path: compare, target add, JALR target masking, and redirect muxing affect control-flow timing.
- Writeback path: memory/ALU/PC+4/immediate writeback muxing is a broad 32-bit datapath.
- Pipeline core: stage registers reduce the architectural datapath per cycle, but the EX-stage branch decision and redirect path remain important.
- Gshare predictor: IF includes PC index extraction, XOR with GHR, PHT read, branch immediate target calculation, and next-PC muxing.

## Optimization Opportunities

Possible future work:

- Reduce decode fanout by grouping or registering selected control fields.
- Split branch target calculation from branch decision if timing becomes a concern.
- Register predictor outputs or introduce a small BTB if the IF prediction path becomes too heavy.
- Parameterize predictor table size and compare area/accuracy tradeoffs.
- Separate synthesis wrappers for debug-heavy and debug-light builds.
- Replace simulation-style memories with more realistic memory macros or inferred memory structures in a future FPGA-oriented flow.

No optimization was applied in Phase 8 because the goal was reporting and honest analysis, not behavior changes.

## Resume-Safe Language

Good wording:

- Built a reproducible Windows-native Yosys synthesis-reporting flow for single-cycle and pipelined RV32I RTL variants.
- Compared area/statistics-style metrics across single-cycle, pipeline, and gshare pipeline wrappers.
- Documented likely critical datapath regions and future optimization opportunities.

Avoid:

- Signoff timing closure
- Industrial physical synthesis
- Synopsys/Cadence-equivalent timing results
- Proven critical-path improvement

