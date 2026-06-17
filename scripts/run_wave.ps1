param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    .\scripts\run_sim.ps1
    Write-Host "Waveform: sim\phase1_basic.vcd"
} finally {
    Pop-Location
}




