import argparse
import random
from pathlib import Path

NOP = 0x00000013


def u32(value):
    return value & 0xFFFFFFFF


def signed12(value):
    if not -2048 <= value <= 2047:
        raise ValueError(value)
    return value & 0xFFF


def encode_r(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def encode_i(imm, rs1, funct3, rd, opcode):
    return (signed12(imm) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((rd & 0x1F) << 7) | opcode


def encode_s(imm, rs2, rs1, funct3=2, opcode=0x23):
    imm12 = signed12(imm)
    return ((imm12 >> 5) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 7) << 12) | ((imm12 & 0x1F) << 7) | opcode


def encode_u(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | opcode


def write_reg(regs, rd, value):
    if rd != 0:
        regs[rd] = u32(value)
    regs[0] = 0


def add_instr(program, asm, word, text, nops):
    program.append(word & 0xFFFFFFFF)
    asm.append(text)
    for _ in range(nops):
        program.append(NOP)
        asm.append("nop")


def generate(seed, count, nops):
    rng = random.Random(seed)
    regs = [0] * 32
    mem = [0] * 16
    program = []
    asm = [f"# Generated hazard-free Phase 5 randomized test, seed=0x{seed:08x}, count={count}"]

    for idx, value in enumerate([3, 7, 11, 19, 23, 31, 37, 43], start=1):
        add_instr(program, asm, encode_i(value, 0, 0, idx, 0x13), f"addi x{idx}, x0, {value}", nops)
        write_reg(regs, idx, value)

    ops = ["addi", "add", "sub", "and", "or", "xor", "lui", "auipc", "sw", "lw"]
    for _ in range(count):
        op = rng.choice(ops)
        pc = len(program) * 4
        rd = rng.randint(1, 15)
        rs1 = rng.randint(0, 15)
        rs2 = rng.randint(0, 15)
        if op == "addi":
            imm = rng.randint(-64, 63)
            add_instr(program, asm, encode_i(imm, rs1, 0, rd, 0x13), f"addi x{rd}, x{rs1}, {imm}", nops)
            write_reg(regs, rd, regs[rs1] + imm)
        elif op == "add":
            add_instr(program, asm, encode_r(0x00, rs2, rs1, 0, rd), f"add x{rd}, x{rs1}, x{rs2}", nops)
            write_reg(regs, rd, regs[rs1] + regs[rs2])
        elif op == "sub":
            add_instr(program, asm, encode_r(0x20, rs2, rs1, 0, rd), f"sub x{rd}, x{rs1}, x{rs2}", nops)
            write_reg(regs, rd, regs[rs1] - regs[rs2])
        elif op == "and":
            add_instr(program, asm, encode_r(0x00, rs2, rs1, 7, rd), f"and x{rd}, x{rs1}, x{rs2}", nops)
            write_reg(regs, rd, regs[rs1] & regs[rs2])
        elif op == "or":
            add_instr(program, asm, encode_r(0x00, rs2, rs1, 6, rd), f"or x{rd}, x{rs1}, x{rs2}", nops)
            write_reg(regs, rd, regs[rs1] | regs[rs2])
        elif op == "xor":
            add_instr(program, asm, encode_r(0x00, rs2, rs1, 4, rd), f"xor x{rd}, x{rs1}, x{rs2}", nops)
            write_reg(regs, rd, regs[rs1] ^ regs[rs2])
        elif op == "lui":
            imm20 = rng.randint(0, 0x00FFF)
            add_instr(program, asm, encode_u(imm20, rd, 0x37), f"lui x{rd}, 0x{imm20:x}", nops)
            write_reg(regs, rd, imm20 << 12)
        elif op == "auipc":
            imm20 = rng.randint(0, 0x0000F)
            add_instr(program, asm, encode_u(imm20, rd, 0x17), f"auipc x{rd}, 0x{imm20:x}", nops)
            write_reg(regs, rd, pc + (imm20 << 12))
        elif op == "sw":
            index = rng.randint(0, len(mem) - 1)
            imm = index * 4
            add_instr(program, asm, encode_s(imm, rs2, 0), f"sw x{rs2}, {imm}(x0)", nops)
            mem[index] = regs[rs2]
        elif op == "lw":
            index = rng.randint(0, len(mem) - 1)
            imm = index * 4
            add_instr(program, asm, encode_i(imm, 0, 2, rd, 0x03), f"lw x{rd}, {imm}(x0)", nops)
            write_reg(regs, rd, mem[index])

    add_instr(program, asm, encode_i(123, 0, 0, 0, 0x13), "addi x0, x0, 123", nops)
    regs[0] = 0
    while len(program) < 256:
        program.append(NOP)
        asm.append("nop")
    return program[:256], asm[:256], regs, mem


def write_outputs(root, seed, program, asm, regs, mem, compat):
    generated = root / "tests" / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    prefix = generated / f"random_pipeline_seed{seed}"
    files = {
        "hex": prefix.with_suffix(".hex"),
        "asm": prefix.with_suffix(".S"),
        "expected": generated / f"random_pipeline_seed{seed}_expected.txt",
    }
    files["hex"].write_text("\n".join(f"{word:08x}" for word in program) + "\n", encoding="ascii")
    files["asm"].write_text("\n".join(asm) + "\n", encoding="ascii")
    files["expected"].write_text(
        "registers\n" + "\n".join(f"x{i}=0x{value:08x}" for i, value in enumerate(regs)) +
        "\n\ndmem\n" + "\n".join(f"mem[{i}]=0x{value:08x}" for i, value in enumerate(mem)) + "\n",
        encoding="ascii",
    )
    if compat:
        tests = root / "tests"
        (tests / "phase5_random.hex").write_text(files["hex"].read_text(encoding="ascii"), encoding="ascii")
        (tests / "phase5_random.S").write_text(files["asm"].read_text(encoding="ascii"), encoding="ascii")
        (tests / "phase5_random_expected_regs.hex").write_text("\n".join(f"{v:08x}" for v in regs) + "\n", encoding="ascii")
        (tests / "phase5_random_expected_dmem.hex").write_text("\n".join(f"{v:08x}" for v in mem) + "\n", encoding="ascii")
    return files


def main():
    parser = argparse.ArgumentParser(description="Generate a deterministic hazard-free RV32I pipeline random test.")
    parser.add_argument("--seed", type=lambda x: int(x, 0), default=0x52564335)
    parser.add_argument("--count", type=int, default=50)
    parser.add_argument("--nops", type=int, default=3)
    parser.add_argument("--compat", action="store_true", help="Also write tests/phase5_random.* files used by the Phase 5 testbench.")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    program, asm, regs, mem = generate(args.seed, args.count, args.nops)
    files = write_outputs(root, args.seed, program, asm, regs, mem, args.compat)
    print(f"Generated random pipeline test seed={args.seed} count={args.count}")
    print(f"hex={files['hex']}")
    print(f"asm={files['asm']}")
    print(f"expected={files['expected']}")


if __name__ == "__main__":
    main()
