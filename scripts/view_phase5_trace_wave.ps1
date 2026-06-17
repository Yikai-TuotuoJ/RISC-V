param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$vcd = Join-Path $root "sim\phase5_pipeline_trace.vcd"
if (!(Test-Path $vcd)) {
    throw "Missing waveform $vcd. Run scripts\run_phase5_trace.ps1 first."
}
gtkwave $vcd



