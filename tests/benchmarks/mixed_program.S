# Mixed memory, ALU, and taken-branch microbenchmark.
addi x1, x0, 32
addi x2, x0, 7
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
add  x5, x3, x2
nop
nop
nop
beq  x5, x5, taken
addi x6, x0, 66
addi x7, x0, 77
taken:
addi x8, x0, 8
nop
nop
nop
nop
nop
nop
nop
nop
