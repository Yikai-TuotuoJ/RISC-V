param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$vcd = Join-Path $root "sim\phase5_pipeline_trace.vcd"
$gtkw = Join-Path $root "reports\sim\phase5_pipeline_structure.gtkw"

if (!(Test-Path $vcd)) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_phase5_trace.ps1")
}
if (!(Test-Path $gtkw)) {
    throw "Missing curated GTKWave save file: $gtkw"
}

gtkwave $vcd $gtkw



