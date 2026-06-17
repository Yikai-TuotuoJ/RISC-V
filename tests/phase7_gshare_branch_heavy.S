# Phase 7 gshare branch-heavy directed test.
# NOPs separate dependent operations because forwarding/load-use handling is
# still outside this phase.

addi x1, x0, 0
addi x2, x0, 8
addi x4, x0, 1
nop
nop
nop

loop:
addi x1, x1, 1
nop
nop
nop
bne  x1, x2, loop
nop
nop
nop

addi x3, x0, 123
nop
nop
nop

beq  x4, x4, beq_taken
addi x7, x0, 77
addi x8, x0, 88

beq_taken:
addi x9, x0, 9
nop
nop
nop

bne  x4, x4, bne_not_taken_target
addi x10, x0, 10
nop
nop
nop

bne  x1, x4, bne_taken
addi x11, x0, 11
addi x12, x0, 12

bne_taken:
addi x13, x0, 13
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop

bne_not_taken_target:
