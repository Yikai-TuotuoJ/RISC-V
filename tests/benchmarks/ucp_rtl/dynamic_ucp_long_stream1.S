# dynamic_ucp_long_stream1: warm up monitor, then give stream 1 a five-line hot set
# Phase A: same utility-pressure pattern used to trigger dynamic repartitioning.
addi x1, x0, 0
lw   x3, 0(x1)
addi x1, x0, 8
lw   x4, 0(x1)
addi x1, x0, 16
lw   x5, 0(x1)
addi x1, x0, 0
lw   x6, 0(x1)
addi x1, x0, 8
lw   x7, 0(x1)
addi x1, x0, 16
lw   x8, 0(x1)
addi x1, x0, 128
lw   x9, 0(x1)
addi x1, x0, 132
lw   x10, 0(x1)
addi x1, x0, 136
lw   x11, 0(x1)
addi x1, x0, 128
lw   x12, 0(x1)
addi x1, x0, 0
lw   x13, 0(x1)
addi x1, x0, 8
lw   x14, 0(x1)
addi x1, x0, 16
lw   x15, 0(x1)
# Phase B: stream 1 repeatedly touches five words. Dynamic 3/5 can retain these better than equal 4/4.
addi x1, x0, 128
lw   x16, 0(x1)
addi x1, x0, 132
lw   x17, 0(x1)
addi x1, x0, 136
lw   x18, 0(x1)
addi x1, x0, 140
lw   x19, 0(x1)
addi x1, x0, 144
lw   x20, 0(x1)
addi x1, x0, 128
lw   x16, 0(x1)
addi x1, x0, 132
lw   x17, 0(x1)
addi x1, x0, 136
lw   x18, 0(x1)
addi x1, x0, 140
lw   x19, 0(x1)
addi x1, x0, 144
lw   x20, 0(x1)
addi x1, x0, 128
lw   x16, 0(x1)
addi x1, x0, 132
lw   x17, 0(x1)
addi x1, x0, 136
lw   x18, 0(x1)
addi x1, x0, 140
lw   x19, 0(x1)
addi x1, x0, 144
lw   x20, 0(x1)
addi x1, x0, 128
lw   x16, 0(x1)
addi x1, x0, 132
lw   x17, 0(x1)
addi x1, x0, 136
lw   x18, 0(x1)
addi x1, x0, 140
lw   x19, 0(x1)
addi x1, x0, 144
lw   x20, 0(x1)
addi x1, x0, 128
lw   x16, 0(x1)
addi x1, x0, 132
lw   x17, 0(x1)
addi x1, x0, 136
lw   x18, 0(x1)
addi x1, x0, 140
lw   x19, 0(x1)
addi x1, x0, 144
lw   x20, 0(x1)
