# l3_reuse_after_l2_eviction: force L1/L2 conflicts and check L3 hits
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
addi x1, x0, 16
lw   x9, 0(x1)
addi x1, x0, 0
lw   x10, 0(x1)
