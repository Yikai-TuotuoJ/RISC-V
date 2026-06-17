# Phase 4 hazard-free directed program for the baseline 5-stage pipeline.
# This intentionally inserts NOPs between dependent instructions because Phase 4
# does not implement forwarding or hazard detection yet.

addi x1, x0, 10
nop
nop
nop
addi x2, x0, 20
nop
nop
nop
add  x3, x1, x2
nop
nop
nop
sub  x4, x3, x1
nop
nop
nop
and  x5, x3, x2
nop
nop
nop
or   x6, x1, x2
nop
nop
nop
xor  x7, x1, x2
nop
nop
nop
sw   x3, 0(x0)
nop
nop
nop
lw   x8, 0(x0)
nop
nop
nop
lui  x9, 0x12345
nop
nop
nop
auipc x10, 0x1
nop
nop
nop
beq  x8, x3, beq_target
addi x11, x0, 1
addi x12, x0, 2
beq_target:
addi x11, x0, 3
nop
nop
nop
bne  x1, x2, bne_target
addi x12, x0, 4
addi x13, x0, 5
bne_target:
addi x12, x0, 6
nop
nop
nop
jal  x14, jal_target
addi x13, x0, 7
addi x15, x0, 8
jal_target:
addi x13, x0, 9
nop
nop
nop
addi x16, x0, 288
nop
nop
nop
jalr x17, 0(x16)
addi x18, x0, 10
addi x19, x0, 11
jalr_target:
addi x18, x0, 12
nop
nop
nop
nop
nop
nop
