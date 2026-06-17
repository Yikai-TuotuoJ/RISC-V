param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
New-Item -ItemType Directory -Force -Path $simDir | Out-Null

$rtl = @(
    "rtl/alu.sv",
    "rtl/decoder.sv",
    "rtl/regfile.sv",
    "rtl/imem.sv",
    "rtl/dmem_stub.sv",
    "rtl/branch_predictor.sv",
    "rtl/gshare_branch_predictor.sv",
    "rtl/direct_mapped_dcache.sv",
    "rtl/rv32i_pipeline_core.sv",
    "tb/tb_rv32i_pipeline_core_phase4.sv"
)
$out = Join-Path $simDir "phase4_pipeline_basic.vvp"

Push-Location $root
try {
    iverilog -g2012 -Wall -o $out $rtl
    vvp $out
} finally {
    Pop-Location
}






