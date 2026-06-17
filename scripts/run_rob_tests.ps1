param(
    [switch]$SkipPriorRegressions
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "rob_logs"
$SimLog = Join-Path $LogDir "rob_validation.log"
$Exe = Join-Path $SimDir "tb_tomasulo_rob.vvp"

New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null

if (-not $SkipPriorRegressions) {
    Write-Host "Running prior Tomasulo/scoreboard regression reference..."
    & (Join-Path $PSScriptRoot "run_tomasulo_tests.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: prior Tomasulo regression failed"
    }
}

Write-Host "Compiling Phase 18 ROB validation..."
& iverilog -g2012 -Wall -s tb_tomasulo_rob -o $Exe `
    (Join-Path $Root "rtl\tomasulo_alu_model.sv") `
    (Join-Path $Root "rtl\tomasulo_rob_experiment_core.sv") `
    (Join-Path $Root "tb\tb_tomasulo_rob.sv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: ROB compile failed"
}

Write-Host "Running Phase 18 ROB validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: ROB simulation failed"
    }
} finally {
    Pop-Location
}

Write-Host "Generating Phase 18 ROB reports..."
& python3 (Join-Path $PSScriptRoot "summarize_rob_reports.py") `
    --log $SimLog `
    --markdown (Join-Path $ReportPerfDir "rob_summary.md") `
    --csv (Join-Path $ReportPerfDir "rob_summary.csv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: ROB report generation failed"
}

foreach ($RequiredFile in @(
    (Join-Path $ReportSimDir "rob_trace.log"),
    (Join-Path $ReportPerfDir "rob_summary.md"),
    (Join-Path $ReportPerfDir "rob_summary.csv")
)) {
    if (-not (Test-Path $RequiredFile)) {
        throw "FAIL: required ROB artifact missing: $RequiredFile"
    }
}

Write-Host "PASS: Phase 18 ROB validation and reports completed."
