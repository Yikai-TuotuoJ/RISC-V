# Phase 6 branch predictor directed test.
# Hazard-free NOP spacing is used because forwarding/load-use stalls are not implemented yet.

addi x1, x0, 0
nop
nop
nop
addi x2, x0, 4
nop
nop
nop
loop:
addi x1, x1, 1
nop
nop
nop
bne x1, x2, loop
nop
nop
nop
addi x3, x0, 123
nop
nop
nop
addi x4, x0, 1
nop
nop
nop
beq x4, x4, beq_target
addi x7, x0, 77      # wrong path for taken BEQ, must be flushed
addi x8, x0, 88      # wrong path for taken BEQ, must be flushed
beq_target:
addi x9, x0, 9
nop
nop
nop
bne x4, x4, skip_not_taken
addi x11, x0, 11     # correct path for not-taken BNE
nop
nop
nop
skip_not_taken:
addi x0, x0, 0
