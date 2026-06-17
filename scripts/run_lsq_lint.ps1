param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Log = Join-Path $Root "reports\lint_lsq.log"
New-Item -ItemType Directory -Force -Path (Join-Path $Root "reports") | Out-Null

Push-Location $Root
try {
    verilator_bin --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC `
        rtl\tomasulo_rob_lsq_experiment_core.sv 2>&1 | Tee-Object -FilePath $Log
} finally {
    Pop-Location
}
