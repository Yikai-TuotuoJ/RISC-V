# Phase 1 directed program, manually encoded RV32I.
# Expected final values:
# x0=0, x1=5, x2=12, x3=17, x4=5, x5=4, x6=13, x7=9, x8=-8, x9=-7

addi x1, x0, 5
addi x2, x0, 12
add  x3, x1, x2
sub  x4, x3, x2
and  x5, x1, x2
or   x6, x1, x2
xor  x7, x1, x2
addi x8, x0, -8
addi x9, x8, 1
addi x0, x0, 123
addi x0, x0, 0
addi x0, x0, 0

