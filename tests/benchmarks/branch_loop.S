# Branch-heavy loop microbenchmark.
addi x1, x0, 0
addi x2, x0, 5
nop
nop
nop
loop:
addi x1, x1, 1
nop
nop
nop
bne  x1, x2, loop
nop
nop
nop
addi x3, x0, 123
nop
nop
nop
nop
nop
nop
nop
nop
