# Phase 2 directed program, manually encoded RV32I.
# Validates Phase 1 ALU ops plus LW, SW, BEQ, BNE, and x0 hardwiring.

addi x1, x0, 100      # base address
addi x2, x0, 42       # store/load value
add  x10, x1, x2      # existing ADD still works: 142
sub  x11, x10, x2     # existing SUB still works: 100
and  x12, x1, x2      # 32
or   x13, x1, x2      # 110
xor  x14, x1, x2      # 78
sw   x2, 0(x1)        # mem[100] = 42
lw   x3, 0(x1)        # x3 = 42
beq  x2, x3, beq_taken
addi x4, x0, 1        # skipped
beq_taken:
addi x4, x0, 2
beq  x2, x0, beq_not_taken_fail
addi x6, x0, 6        # executed because BEQ is not taken
beq_not_taken_fail:
bne  x2, x0, bne_taken
addi x5, x0, 1        # skipped
bne_taken:
addi x5, x0, 3
bne  x2, x3, bne_not_taken_fail
addi x7, x0, 7        # executed because BNE is not taken
bne_not_taken_fail:
addi x0, x0, 123      # ignored x0 write
addi x0, x0, 0
addi x0, x0, 0
