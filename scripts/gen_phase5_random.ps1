param()
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Tests = Join-Path $Root "tests"
$Seed = 0x52564335
$Nop = 0x00000013
New-Item -ItemType Directory -Force -Path $Tests | Out-Null

function U32([Int64]$Value) {
    return [UInt32]($Value -band 0xffffffffL)
}

function Hex32([Int64]$Value) {
    return (U32 $Value).ToString("x8")
}

function Signed12([Int64]$Value) {
    if ($Value -lt -2048 -or $Value -gt 2047) { throw "Immediate out of signed-12 range: $Value" }
    return $Value -band 0xfff
}

function Encode-R([Int64]$Funct7, [Int64]$Rs2, [Int64]$Rs1, [Int64]$Funct3, [Int64]$Rd) {
    return (($Funct7 -band 0x7f) -shl 25) -bor (($Rs2 -band 0x1f) -shl 20) -bor (($Rs1 -band 0x1f) -shl 15) -bor (($Funct3 -band 7) -shl 12) -bor (($Rd -band 0x1f) -shl 7) -bor 0x33
}

function Encode-I([Int64]$Imm, [Int64]$Rs1, [Int64]$Funct3, [Int64]$Rd, [Int64]$Opcode) {
    return ((Signed12 $Imm) -shl 20) -bor (($Rs1 -band 0x1f) -shl 15) -bor (($Funct3 -band 7) -shl 12) -bor (($Rd -band 0x1f) -shl 7) -bor $Opcode
}

function Encode-S([Int64]$Imm, [Int64]$Rs2, [Int64]$Rs1) {
    $imm12 = Signed12 $Imm
    return (($imm12 -shr 5) -shl 25) -bor (($Rs2 -band 0x1f) -shl 20) -bor (($Rs1 -band 0x1f) -shl 15) -bor (2 -shl 12) -bor (($imm12 -band 0x1f) -shl 7) -bor 0x23
}

function Encode-U([Int64]$Imm20, [Int64]$Rd, [Int64]$Opcode) {
    return (($Imm20 -band 0xfffff) -shl 12) -bor (($Rd -band 0x1f) -shl 7) -bor $Opcode
}

function Write-Reg([UInt32[]]$Regs, [Int64]$Rd, [Int64]$Value) {
    if ($Rd -ne 0) { $Regs[$Rd] = U32 $Value }
    $Regs[0] = 0
}

function Add-Instr([System.Collections.Generic.List[UInt32]]$Program, [System.Collections.Generic.List[string]]$Asm, [Int64]$Word, [string]$Text) {
    [void]$Program.Add((U32 $Word))
    [void]$Asm.Add($Text)
    for ($i = 0; $i -lt 3; $i++) {
        [void]$Program.Add([UInt32]$Nop)
        [void]$Asm.Add("nop")
    }
}

$rng = [System.Random]::new([int]$Seed)
$regs = [UInt32[]]::new(32)
$mem = [UInt32[]]::new(16)
$program = [System.Collections.Generic.List[UInt32]]::new()
$asm = [System.Collections.Generic.List[string]]::new()
[void]$asm.Add(("# Generated hazard-free Phase 5 randomized test, seed=0x{0:x8}" -f $Seed))

$initial = @(3, 7, 11, 19, 23, 31, 37, 43)
for ($idx = 0; $idx -lt $initial.Count; $idx++) {
    $rd = $idx + 1
    $value = $initial[$idx]
    Add-Instr $program $asm (Encode-I $value 0 0 $rd 0x13) "addi x$rd, x0, $value"
    Write-Reg $regs $rd $value
}

$ops = @("addi", "add", "sub", "and", "or", "xor", "lui", "auipc", "sw", "lw")
for ($n = 0; $n -lt 50; $n++) {
    $op = $ops[$rng.Next(0, $ops.Count)]
    $pc = $program.Count * 4
    $rd = $rng.Next(1, 16)
    $rs1 = $rng.Next(0, 16)
    $rs2 = $rng.Next(0, 16)
    switch ($op) {
        "addi" {
            $imm = $rng.Next(-64, 64)
            Add-Instr $program $asm (Encode-I $imm $rs1 0 $rd 0x13) "addi x$rd, x$rs1, $imm"
            Write-Reg $regs $rd ([Int64]$regs[$rs1] + $imm)
        }
        "add" {
            Add-Instr $program $asm (Encode-R 0x00 $rs2 $rs1 0 $rd) "add x$rd, x$rs1, x$rs2"
            Write-Reg $regs $rd ([Int64]$regs[$rs1] + [Int64]$regs[$rs2])
        }
        "sub" {
            Add-Instr $program $asm (Encode-R 0x20 $rs2 $rs1 0 $rd) "sub x$rd, x$rs1, x$rs2"
            Write-Reg $regs $rd ([Int64]$regs[$rs1] - [Int64]$regs[$rs2])
        }
        "and" {
            Add-Instr $program $asm (Encode-R 0x00 $rs2 $rs1 7 $rd) "and x$rd, x$rs1, x$rs2"
            Write-Reg $regs $rd ([Int64]($regs[$rs1] -band $regs[$rs2]))
        }
        "or" {
            Add-Instr $program $asm (Encode-R 0x00 $rs2 $rs1 6 $rd) "or x$rd, x$rs1, x$rs2"
            Write-Reg $regs $rd ([Int64]($regs[$rs1] -bor $regs[$rs2]))
        }
        "xor" {
            Add-Instr $program $asm (Encode-R 0x00 $rs2 $rs1 4 $rd) "xor x$rd, x$rs1, x$rs2"
            Write-Reg $regs $rd ([Int64]($regs[$rs1] -bxor $regs[$rs2]))
        }
        "lui" {
            $imm20 = $rng.Next(0, 0x1000)
            Add-Instr $program $asm (Encode-U $imm20 $rd 0x37) ("lui x$rd, 0x{0:x}" -f $imm20)
            Write-Reg $regs $rd ($imm20 -shl 12)
        }
        "auipc" {
            $imm20 = $rng.Next(0, 0x10)
            Add-Instr $program $asm (Encode-U $imm20 $rd 0x17) ("auipc x$rd, 0x{0:x}" -f $imm20)
            Write-Reg $regs $rd ($pc + ($imm20 -shl 12))
        }
        "sw" {
            $index = $rng.Next(0, $mem.Count)
            $imm = $index * 4
            Add-Instr $program $asm (Encode-S $imm $rs2 0) "sw x$rs2, $imm(x0)"
            $mem[$index] = $regs[$rs2]
        }
        "lw" {
            $index = $rng.Next(0, $mem.Count)
            $imm = $index * 4
            Add-Instr $program $asm (Encode-I $imm 0 2 $rd 0x03) "lw x$rd, $imm(x0)"
            Write-Reg $regs $rd $mem[$index]
        }
    }
}

Add-Instr $program $asm (Encode-I 123 0 0 0 0x13) "addi x0, x0, 123"
$regs[0] = 0
while ($program.Count -lt 256) {
    [void]$program.Add([UInt32]$Nop)
    [void]$asm.Add("nop")
}

$programLines = $program | Select-Object -First 256 | ForEach-Object { $_.ToString("x8") }
Set-Content -Path (Join-Path $Tests "phase5_random.hex") -Value $programLines -Encoding ASCII
Set-Content -Path (Join-Path $Tests "phase5_random.S") -Value ($asm | Select-Object -First 256) -Encoding ASCII
Set-Content -Path (Join-Path $Tests "phase5_random_expected_regs.hex") -Value ($regs | ForEach-Object { $_.ToString("x8") }) -Encoding ASCII
Set-Content -Path (Join-Path $Tests "phase5_random_expected_dmem.hex") -Value ($mem | ForEach-Object { $_.ToString("x8") }) -Encoding ASCII
Write-Host ("Generated phase5_random with seed 0x{0:x8}, 256 instructions" -f $Seed)



