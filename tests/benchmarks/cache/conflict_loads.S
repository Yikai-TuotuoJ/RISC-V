# Preload mem[0] = 10 and mem[4] = 20. Byte addresses 0 and 16 map to the same 4-line cache index.
addi x1, x0, 0
addi x2, x0, 16
lw   x3, 0(x1)
lw   x4, 0(x1)
lw   x5, 0(x2)
lw   x6, 0(x1)
add  x7, x3, x5
