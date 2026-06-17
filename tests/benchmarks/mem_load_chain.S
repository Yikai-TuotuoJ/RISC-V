# Phase 10 memory-latency benchmark: mem_load_chain.
addi x1, x0, 64
addi x2, x0, 11
sw   x2, 0(x1)
lw   x3, 0(x1)
addi x4, x3, 1
add  x5, x4, x3
nop
nop
nop
nop
nop
nop
nop
nop
