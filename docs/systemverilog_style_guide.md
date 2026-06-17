# SystemVerilog Style Guide

This repository now uses open-source-tool-compatible SystemVerilog as the primary RTL and testbench language.

## File Naming

- Use `.sv` for RTL and testbench source files.
- Keep generated netlists, reports, VCD files, and hex files in their existing formats.
- Do not add new `.v` source files unless there is a tool-compatibility reason and the reason is documented.

## RTL Signal Style

- Prefer `logic` for internal signals and module ports.
- Avoid legacy `reg` and `wire` in new RTL unless a tool limitation makes them clearer.
- Use explicit continuous assignments for derived combinational signals:

```systemverilog
logic [6:0] opcode;
assign opcode = instr[6:0];
```

Do not write this for changing inputs:

```systemverilog
logic [6:0] opcode = instr[6:0]; // initialization, not continuous assignment
```

## Procedural Blocks

- Use `always_ff` for sequential logic.
- Use nonblocking assignments, `<=`, in sequential logic.
- Use `always_comb` for combinational logic.
- Use blocking assignments, `=`, in combinational logic.
- Give every combinational output a default assignment before `case` or `if` trees.
- Avoid inferred latches.
- Avoid multiple procedural drivers for the same signal.

## Reset Style

- Preserve the existing active-low reset style unless a phase explicitly changes it.
- Keep reset behavior obvious and deterministic.
- Do not change architectural reset behavior during a syntax-only refactor.

## Synthesizable RTL Boundary

- Keep synthesizable modules under `rtl/`.
- Do not use UVM, classes, randomize, constraints, DPI, interfaces, modports, or complex packages under `rtl/`.
- Avoid assertions in synthesizable RTL unless the phase explicitly approves them and all tools accept them.
- Keep testbench-only behavior under `tb/` and scripts.

## Tool Compatibility

The flow targets Windows-native open-source tools:

- Icarus Verilog with `-g2012`
- Verilator lint
- Yosys with `read_verilog -sv`

Prefer compatibility over clever syntax. If a SystemVerilog feature breaks Icarus, Verilator, or Yosys, simplify the code.

## Module Interfaces

- Preserve existing module interfaces unless the phase explicitly allows an interface change.
- Avoid SystemVerilog `interface` constructs for now.
- Keep pipeline debug and performance-counter outputs explicit.

## Verification Expectations

After any behavior-affecting change:

- Run the relevant PowerShell simulation script.
- Preserve clear `PASS` / `FAIL` output.
- Preserve waveform generation.
- Run Verilator lint and Yosys synthesis checks when available.
- Update documentation and resume notes when behavior, workflow, or limitations change.
