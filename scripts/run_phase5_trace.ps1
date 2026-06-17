param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$reportDir = Join-Path $root "reports"
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $simDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportSimDir | Out-Null

$rtl = @(
    "rtl/alu.sv",
    "rtl/decoder.sv",
    "rtl/regfile.sv",
    "rtl/imem.sv",
    "rtl/dmem_stub.sv",
    "rtl/branch_predictor.sv",
    "rtl/gshare_branch_predictor.sv",
    "rtl/direct_mapped_dcache.sv",
    "rtl/rv32i_pipeline_core.sv",
    "tb/tb_rv32i_pipeline_core_phase5_trace.sv"
)
$out = Join-Path $simDir "phase5_pipeline_trace.vvp"
$log = Join-Path $reportSimDir "phase5_trace_sim.log"

Push-Location $root
try {
    iverilog -g2012 -Wall -o $out $rtl 2>&1 | Tee-Object -FilePath $log
    $simOutput = vvp $out 2>&1
    $simOutput | Tee-Object -FilePath $log -Append
    $simOutput | ForEach-Object { Write-Host $_ }
    if ($simOutput -match "FAIL:") {
        throw "Phase 5 trace simulation reported FAIL"
    }
    Write-Host "Trace log: reports\sim\pipeline_trace.log"
    Write-Host "Trace CSV: reports\phase5_pipeline_trace.csv"
    Write-Host "Simulation log: reports\sim\phase5_trace_sim.log"
    Write-Host "Waveform: sim\phase5_pipeline_trace.vcd"
} finally {
    Pop-Location
}






