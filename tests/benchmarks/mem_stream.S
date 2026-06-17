# Scheduled store/load microbenchmark.
addi x1, x0, 64
addi x2, x0, 42
nop
nop
nop
sw   x2, 0(x1)
nop
nop
nop
lw   x3, 0(x1)
nop
nop
nop
nop
nop
nop
nop
nop
