# VS Code RTL Workflow

This project can be driven from VS Code while keeping the Windows-native open-source toolchain underneath.

## Recommended Extensions

The workspace recommends these extensions in `.vscode/extensions.json`:

- `mshr-h.veriloghdl`: Verilog/SystemVerilog syntax, snippets, and lint integration.
- `wavetrace.wavetrace`: native VCD waveform viewing inside VS Code.
- `lramseyer.vaporview`: another native waveform viewer option for VCD/FST/GHW.
- `surfer-project.surfer`: VS Code integration for the Surfer waveform viewer.
- `ms-vscode.powershell`: PowerShell task/script support.
- `ms-python.python`: Python editing support for random-test generators.

Do not install all waveform viewers at once if file associations conflict. Start with WaveTrace or VaporView for quick VCD viewing. Keep GTKWave for the curated saved view.

## VS Code Tasks

Open the command palette and run `Tasks: Run Task`, then choose one of:

- `RISC-V: Full Pipeline Regression`
- `RISC-V: Phase 5 Trace + Wave`
- `RISC-V: Phase 5 Random Test`
- `RISC-V: Verilator Lint Phase 5`
- `RISC-V: Yosys Synth Phase 5`
- `RISC-V: Open GTKWave Curated View`

The tasks call the existing PowerShell scripts, so the command-line flow and VS Code flow stay aligned.

## Waveform Viewing Options

### Option A: VS Code Native Viewer

Run the `RISC-V: Phase 5 Trace + Wave` task, then open:

```text
sim/phase5_pipeline_trace.vcd
```

If WaveTrace, VaporView, or Surfer is installed and owns `.vcd`, VS Code should open the waveform in-editor.

### Option B: Curated GTKWave View

Run:

```text
RISC-V: Open GTKWave Curated View
```

This opens:

```text
sim/phase5_pipeline_trace.vcd
reports/sim/phase5_pipeline_structure.gtkw
```

This is still the best view for the hand-picked pipeline, decoder, ALU, memory, and writeback signal groups.

## Notes

- VS Code extensions are UI conveniences. The source-of-truth verification remains the PowerShell scripts.
- The recommended HDL extension expects tools such as Verilator or Icarus to be on `PATH`; the project scripts already activate OSS CAD Suite through `scripts/setup_oss_cad_env.ps1`.
- If an extension cannot find tools from the VS Code UI, launch VS Code from a PowerShell terminal after running the setup script, or use the repository tasks instead.
