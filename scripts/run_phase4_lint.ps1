param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$log = Join-Path $reportDir "lint_phase4.log"

Push-Location $root
try {
    verilator_bin --lint-only --timing --top-module tb_rv32i_pipeline_core_phase4 -Wall --Wno-fatal --Wno-UNUSEDSIGNAL --Wno-PINMISSING rtl/alu.sv rtl/decoder.sv rtl/regfile.sv rtl/imem.sv rtl/dmem_stub.sv rtl/branch_predictor.sv rtl/gshare_branch_predictor.sv rtl/direct_mapped_dcache.sv rtl/rv32i_pipeline_core.sv tb/tb_rv32i_pipeline_core_phase4.sv 2>&1 | Tee-Object -FilePath $log
} finally {
    Pop-Location
}







