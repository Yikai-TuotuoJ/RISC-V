param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$vcd = Join-Path $root "sim\phase4_pipeline_basic.vcd"
if (-not (Test-Path $vcd)) {
    & (Join-Path $PSScriptRoot "run_phase4_wave.ps1")
}

gtkwave $vcd



