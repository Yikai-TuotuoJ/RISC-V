# Mixed store/load/ALU memory program for CPI and cache-counter comparison.
addi x1, x0, 96
addi x2, x0, 5
sw   x2, 0(x1)
lw   x3, 0(x1)
addi x4, x3, 7
sw   x4, 4(x1)
lw   x5, 4(x1)
add  x6, x3, x5
