param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    .\scripts\run_phase2_sim.ps1
    Write-Host "Waveform: sim\phase2_mem_branch.vcd"
} finally {
    Pop-Location
}



