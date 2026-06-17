# Phase 10.5 SystemVerilog Refactor

Phase 10.5 migrated the source RTL and testbench collateral from Verilog-style `.v` files to open-source-tool-compatible SystemVerilog `.sv` files.

This is a refactor phase. No CPU architecture feature was added.

## What Changed

- Renamed RTL files under `rtl/` from `.v` to `.sv`.
- Renamed testbench files under `tb/` from `.v` to `.sv`.
- Updated PowerShell simulation, benchmark, lint, and synthesis scripts to reference `.sv` files.
- Updated Icarus Verilog invocations from `-g2005` to `-g2012`.
- Updated Yosys scripts to use `read_verilog -sv`.
- Converted synthesizable RTL internals to use `logic`, `always_ff`, and `always_comb` where compatible.
- Converted testbench signal declarations from legacy `reg`/`wire` to `logic` where practical.

## Compatibility Fix During Migration

A useful SystemVerilog migration issue was found and fixed in the decoder.

Legacy Verilog allowed this net declaration style:

```verilog
wire [6:0] opcode = instr[6:0];
```

After converting `wire` to `logic`, the equivalent text would become an initialization, not a continuous assignment:

```systemverilog
logic [6:0] opcode = instr[6:0];
```

That would capture only an initial value and break decode. The fix was to use explicit continuous assignments:

```systemverilog
logic [6:0] opcode;
assign opcode = instr[6:0];
```

This is now captured in `docs/systemverilog_style_guide.md` for future phases.

## Tool Flow

Icarus commands now use:

```powershell
iverilog -g2012 ...
```

Yosys scripts now use:

```text
read_verilog -sv ...
```

Verilator accepts the `.sv` files directly in the existing lint scripts.

## Intentionally Avoided Features

The project intentionally does not use advanced SystemVerilog methodology yet:

- no UVM
- no classes
- no interfaces or modports
- no DPI
- no complex packages
- no advanced assertions

This keeps the code friendly to Icarus, Verilator, and Yosys on Windows.

## Validation

After the refactor, the existing simulation, branch/gshare, benchmark, memory-latency, lint, and synthesis flows were rerun. Behavior is preserved under the SystemVerilog flow.

## Current Limitations

Generated Yosys netlists may still use `.v` output names because they are generated Verilog netlists, not hand-maintained source files. Source RTL and testbench files now use `.sv`.
