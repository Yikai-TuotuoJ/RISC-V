from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tests" / "benchmarks" / "smt"


def r_type(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def i_type(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def s_type(imm, rs2, rs1, funct3, opcode=0x23):
    imm &= 0xFFF
    return ((imm >> 5) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((imm & 0x1F) << 7) | opcode


def b_type(imm, rs2, rs1, funct3, opcode=0x63):
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | opcode


def j_type(imm, rd, opcode=0x6F):
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | ((rd & 0x1F) << 7) | opcode


def addi(rd, rs1, imm): return i_type(imm, rs1, 0, rd, 0x13)
def lw(rd, imm, rs1): return i_type(imm, rs1, 2, rd, 0x03)
def sw(rs2, imm, rs1): return s_type(imm, rs2, rs1, 2)
def add(rd, rs1, rs2): return r_type(0, rs2, rs1, 0, rd)
def sub(rd, rs1, rs2): return r_type(0x20, rs2, rs1, 0, rd)
def bne(rs1, rs2, imm): return b_type(imm, rs2, rs1, 1)
def beq(rs1, rs2, imm): return b_type(imm, rs2, rs1, 0)
def jal(rd, imm): return j_type(imm, rd)


NOP = 0x00000013


def emit(name, thread, instrs, asm):
    while len(instrs) < 256:
        instrs.append(NOP)
    (OUT / f"{name}_t{thread}.hex").write_text("\n".join(f"{x:08x}" for x in instrs) + "\n")
    (OUT / f"{name}_t{thread}.S").write_text("\n".join(asm) + "\n")


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    emit("context_basic", 0,
         [addi(1, 0, 5), addi(2, 0, 7), add(3, 1, 2), addi(0, 0, 99), addi(4, 0, 10)],
         ["addi x1, x0, 5", "addi x2, x0, 7", "add x3, x1, x2", "addi x0, x0, 99", "addi x4, x0, 10"])
    emit("context_basic", 1,
         [addi(1, 0, 100), addi(2, 0, 1), sub(3, 1, 2), addi(4, 0, 20)],
         ["addi x1, x0, 100", "addi x2, x0, 1", "sub x3, x1, x2", "addi x4, x0, 20"])

    emit("hazard_memory", 0,
         [addi(1, 0, 0), lw(2, 0, 1), add(3, 2, 2), sw(3, 8, 1), lw(4, 8, 1), addi(5, 0, 1)],
         ["addi x1, x0, 0", "lw x2, 0(x1)", "add x3, x2, x2", "sw x3, 8(x1)", "lw x4, 8(x1)", "addi x5, x0, 1"])
    emit("hazard_memory", 1,
         [addi(1, 0, 4), lw(2, 0, 1), addi(3, 2, 5), sw(3, 12, 0), lw(4, 12, 0), addi(5, 0, 2)],
         ["addi x1, x0, 4", "lw x2, 0(x1)", "addi x3, x2, 5", "sw x3, 12(x0)", "lw x4, 12(x0)", "addi x5, x0, 2"])

    emit("branch_jump", 0,
         [addi(1, 0, 1), addi(2, 0, 1), beq(1, 2, 8), addi(5, 0, 1), addi(5, 0, 55), addi(6, 0, 66)],
         ["addi x1, x0, 1", "addi x2, x0, 1", "beq x1, x2, skip", "addi x5, x0, 1", "skip: addi x5, x0, 55", "addi x6, x0, 66"])
    emit("branch_jump", 1,
         [addi(1, 0, 1), jal(7, 8), addi(5, 0, 1), addi(5, 0, 77), addi(6, 0, 88)],
         ["addi x1, x0, 1", "jal x7, target", "addi x5, x0, 1", "target: addi x5, x0, 77", "addi x6, x0, 88"])

    hot0 = [addi(1, 0, 0)]
    hot0_asm = ["addi x1, x0, 0"]
    for rd, off in [(2, 0), (3, 8), (4, 0), (5, 8), (6, 0), (7, 8), (8, 0), (9, 8), (10, 0), (11, 8), (12, 0), (13, 8)]:
        hot0.append(lw(rd, off, 1))
        hot0_asm.append(f"lw x{rd}, {off}(x1)")
    emit("smt_ucp_hot_stream", 0, hot0, hot0_asm)

    stream1 = [addi(1, 0, 32)]
    stream1_asm = ["addi x1, x0, 32"]
    for idx, rd in enumerate(range(2, 14)):
        off = idx * 4
        stream1.append(lw(rd, off, 1))
        stream1_asm.append(f"lw x{rd}, {off}(x1)")
    emit("smt_ucp_hot_stream", 1, stream1, stream1_asm)

    balanced0 = [addi(1, 0, 0), lw(2, 0, 1), lw(3, 4, 1), lw(4, 8, 1), lw(5, 12, 1), lw(6, 0, 1), lw(7, 4, 1), lw(8, 8, 1), lw(9, 12, 1)]
    balanced1 = [addi(1, 0, 32), lw(2, 0, 1), lw(3, 4, 1), lw(4, 8, 1), lw(5, 12, 1), lw(6, 0, 1), lw(7, 4, 1), lw(8, 8, 1), lw(9, 12, 1)]
    emit("smt_ucp_balanced", 0, balanced0, ["addi x1, x0, 0", "balanced repeated loads"])
    emit("smt_ucp_balanced", 1, balanced1, ["addi x1, x0, 32", "balanced repeated loads"])


if __name__ == "__main__":
    main()
