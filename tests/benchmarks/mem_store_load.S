# Phase 10 memory-latency benchmark: mem_store_load.
addi x1, x0, 80
addi x2, x0, 21
addi x3, x0, 22
sw   x2, 0(x1)
sw   x3, 4(x1)
lw   x4, 0(x1)
lw   x5, 4(x1)
add  x6, x4, x5
nop
nop
nop
nop
nop
nop
nop
nop
