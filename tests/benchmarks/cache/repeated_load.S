# Preload mem[16] = 55 in the testbench. First LW misses, second LW should hit.
addi x1, x0, 64
lw   x3, 0(x1)
lw   x4, 0(x1)
add  x5, x3, x4
addi x6, x5, 1
addi x0, x0, 77
