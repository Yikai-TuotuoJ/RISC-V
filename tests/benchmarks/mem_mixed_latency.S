# Phase 10 memory-latency benchmark: mem_mixed_latency.
addi x1, x0, 96
addi x2, x0, 5
sw   x2, 0(x1)
lw   x3, 0(x1)
addi x4, x3, 10
sw   x4, 4(x1)
lw   x5, 4(x1)
beq  x5, x4, taken
addi x6, x0, 99
taken:
addi x7, x0, 7
nop
nop
nop
nop
nop
nop
nop
nop
