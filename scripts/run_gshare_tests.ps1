param(
    [switch]$SkipRegression
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $simDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportSimDir | Out-Null

Push-Location $root
try {
    if (-not $SkipRegression) {
        powershell -ExecutionPolicy Bypass -File .\scripts\run_pipeline_tests.ps1 -SkipLint -SkipSynth
        powershell -ExecutionPolicy Bypass -File .\scripts\run_branch_predictor_tests.ps1 -SkipRegression
    }

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
        "tb/tb_rv32i_pipeline_core_phase7_gshare.sv"
    )
    $out = Join-Path $simDir "phase7_gshare.vvp"
    $log = Join-Path $reportSimDir "phase7_gshare.log"

    iverilog -g2012 -Wall -o $out $rtl 2>&1 | Tee-Object -FilePath $log
    $simOutput = vvp $out 2>&1
    $simOutput | Tee-Object -FilePath $log -Append
    if ($simOutput -match "FAIL:") {
        throw "Phase 7 gshare simulation reported FAIL"
    }
    Write-Host "Gshare report: reports\sim\gshare_branch_prediction_report.log"
    Write-Host "Gshare trace: reports\sim\gshare_branch_prediction_trace.log"
    Write-Host "Waveform: sim\phase7_gshare.vcd"
    Write-Host "PASS: Phase 7 gshare flow passed"
} finally {
    Pop-Location
}




