# Phase 3 directed program, manually encoded RV32I.
# Validates JAL, JALR, LUI, AUIPC, link writes, target selection, and x0 hardwiring.

lui   x1, 0x12345       # x1 = 0x12345000
auipc x2, 0x1           # pc=4, x2 = 0x00001004
addi  x3, x0, 28        # JALR target byte address
jal   x4, jal_target    # x4 = 16, skip next instruction
addi  x5, x0, 1         # skipped by JAL
jal_target:
addi  x5, x0, 2
jalr  x6, 0(x3)         # x6 = 28, target = 28
jalr_target:
addi  x7, x0, 7
jal   x0, jal_x0_target # no link write because rd=x0
addi  x8, x0, 1         # skipped by JAL x0
jal_x0_target:
addi  x8, x0, 8
addi  x0, x0, 123       # ignored x0 write
addi  x0, x0, 0
addi  x0, x0, 0
