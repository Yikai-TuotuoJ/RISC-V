# Store miss uses write-through/write-allocate, then the following LW should read the new value.
addi x1, x0, 80
addi x2, x0, 44
sw   x2, 0(x1)
lw   x3, 0(x1)
addi x4, x3, 1
addi x0, x0, 99
