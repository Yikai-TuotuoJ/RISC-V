param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$ys = Join-Path $reportDir "phase4_synth.ys"
$log = Join-Path $reportDir "synth_phase4.log"

@"
read_verilog -sv rtl/alu.sv rtl/decoder.sv rtl/regfile.sv rtl/imem.sv rtl/dmem_stub.sv rtl/branch_predictor.sv rtl/gshare_branch_predictor.sv rtl/direct_mapped_dcache.sv rtl/rv32i_pipeline_core.sv
hierarchy -top rv32i_pipeline_core
proc
opt
memory
opt
techmap
opt
stat
check
"@ | Set-Content -LiteralPath $ys -Encoding ASCII

Push-Location $root
try {
    yosys -s $ys 2>&1 | Tee-Object -FilePath $log
} finally {
    Pop-Location
}






