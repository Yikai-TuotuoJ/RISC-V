param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$log = Join-Path $reportDir "lint_phase1.log"

Push-Location $root
try {
    verilator_bin --lint-only --timing --top-module tb_rv32i_core_phase3 -Wall --Wno-fatal --Wno-UNUSEDSIGNAL rtl/alu.sv rtl/decoder.sv rtl/regfile.sv rtl/imem.sv rtl/dmem_stub.sv rtl/rv32i_core.sv tb/tb_rv32i_core_phase3.sv 2>&1 | Tee-Object -FilePath $log
} finally {
    Pop-Location
}










