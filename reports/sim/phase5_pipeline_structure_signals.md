# Phase 5 Curated Waveform Signal List

Use this save file:

```powershell
gtkwave sim\phase5_pipeline_trace.vcd reports\sim\phase5_pipeline_structure.gtkw
```

## Groups

1. Clock / reset / cycle counters
2. Architectural trace ports: IF, ID, EX, MEM, WB valid/PC/instruction
3. Redirect and flush control
4. IF/ID pipeline register
5. Decoder instruction fields and control outputs
6. ID/EX pipeline register
7. EX ALU inputs/op/result
8. EX/MEM pipeline register
9. Data memory interface
10. MEM/WB and writeback mux result
11. Register file read/write interface

## ALU op encoding

- 0: ADD
- 1: SUB
- 2: AND
- 3: OR
- 4: XOR

## WB select encoding

- 0: ALU result
- 1: memory read data
- 2: PC + 4 link value
- 3: immediate value for LUI
