# Phase 4: Baseline 5-Stage Pipelined RV32I CPU

## Goal

Phase 4 adds a new 5-stage pipelined CPU while preserving the existing single-cycle core as the reference implementation.

The pipeline stages are:

- IF: instruction fetch
- ID: instruction decode and register read
- EX: ALU, branch compare, and target calculation
- MEM: data memory access
- WB: register writeback

## Key Files

- `rtl/rv32i_pipeline_core.sv`: new baseline pipelined core
- `rtl/rv32i_core.sv`: existing single-cycle reference core, left in place
- `tb/tb_rv32i_pipeline_core_phase4.sv`: self-checking Phase 4 pipeline testbench
- `tests/phase4_pipeline_basic.S`: human-readable directed program
- `tests/phase4_pipeline_basic.hex`: hand-encoded directed program loaded by instruction memory
- `sim/phase4_pipeline_basic.vcd`: generated waveform
- `reports/synth_phase4.log`: Yosys synthesis sanity log

## Implemented Pipeline Behavior

The new pipeline core keeps the Phase 3 instruction subset:

- ADD, SUB, AND, OR, XOR
- ADDI
- LW, SW
- BEQ, BNE
- JAL, JALR
- LUI, AUIPC

The design uses pipeline registers between IF/ID, ID/EX, EX/MEM, and MEM/WB. Control signals are decoded in ID and carried down the pipeline with the instruction data they control.

The EX stage resolves branches and jumps. When a redirect is taken, the younger IF/ID and ID/EX instructions are invalidated and the PC is redirected to the branch or jump target.

## Intentional Limitations

Phase 4 does not implement forwarding or hazard detection. Directed pipeline programs must insert enough NOPs between producer and consumer instructions so dependent reads observe committed register-file values.

Phase 4 also does not implement:

- load-use stalls
- general RAW hazard detection
- EX/MEM or MEM/WB forwarding
- branch prediction
- precise exception handling
- CSR support
- interrupts
- caches
- formal verification

These are future phases.

## Verification

Run the Phase 4 directed simulation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase4_sim.ps1
```

Generate the waveform:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase4_wave.ps1
```

Run lint:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase4_lint.ps1
```

Run synthesis sanity:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase4_synth.ps1
```

The Phase 4 directed test checks:

- preserved ALU behavior
- word store and load
- LUI and AUIPC
- BEQ and BNE redirect behavior
- JAL and JALR redirect and link-register behavior
- x0 remains hardwired to zero
- data memory writeback is visible

## Debug Notes

Open the waveform with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\view_phase4_wave.ps1
```

Useful signals to inspect include `pc`, `if_id_*`, `id_ex_*`, `ex_mem_*`, `mem_wb_*`, `ex_redirect`, `ex_redirect_target`, `wb_we`, and `wb_data`.

## Resume Value

This phase demonstrates the ability to refactor a working single-cycle CPU into a staged microarchitecture, carry control signals through pipeline registers, preserve a reference design, add control-flow flushing, and validate the design with open-source simulation, lint, waveform, and synthesis sanity flows.

