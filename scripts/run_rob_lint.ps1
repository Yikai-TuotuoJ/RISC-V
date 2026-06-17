param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Log = Join-Path $Root "reports\lint_rob.log"
New-Item -ItemType Directory -Force -Path (Join-Path $Root "reports") | Out-Null

Push-Location $Root
try {
    verilator_bin --lint-only -Wall `
        rtl\tomasulo_alu_model.sv `
        rtl\tomasulo_rob_experiment_core.sv 2>&1 | Tee-Object -FilePath $Log
} finally {
    Pop-Location
}
