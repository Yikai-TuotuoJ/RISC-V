# shared_l2_reuse: two logical streams, private L1 misses, shared L2 hits
addi x1, x0, 0
lw   x3, 0(x1)
addi x1, x0, 8
lw   x4, 0(x1)
addi x1, x0, 0
lw   x5, 0(x1)
addi x1, x0, 128
lw   x6, 0(x1)
addi x1, x0, 136
lw   x7, 0(x1)
addi x1, x0, 128
lw   x8, 0(x1)
