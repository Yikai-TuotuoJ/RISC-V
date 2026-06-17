param(
    [switch]$SkipPriorRegressions
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "tomasulo_logs"
$SimLog = Join-Path $LogDir "tomasulo_validation.log"
$Exe = Join-Path $SimDir "tb_tomasulo_experiment.vvp"

New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null

if (-not $SkipPriorRegressions) {
    Write-Host "Running prior scoreboard/SMT/cache/UCP regression reference..."
    & (Join-Path $PSScriptRoot "run_scoreboard_tests.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: prior scoreboard/SMT/cache/UCP regression failed"
    }
}

Write-Host "Compiling Phase 17 Tomasulo-style validation..."
& iverilog -g2012 -Wall -s tb_tomasulo_experiment -o $Exe `
    (Join-Path $Root "rtl\tomasulo_alu_model.sv") `
    (Join-Path $Root "rtl\tomasulo_experiment_core.sv") `
    (Join-Path $Root "tb\tb_tomasulo_experiment.sv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Tomasulo compile failed"
}

Write-Host "Running Phase 17 Tomasulo-style validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: Tomasulo simulation failed"
    }
} finally {
    Pop-Location
}

Write-Host "Generating Phase 17 Tomasulo reports..."
& python3 (Join-Path $PSScriptRoot "summarize_tomasulo_reports.py") `
    --log $SimLog `
    --markdown (Join-Path $ReportPerfDir "tomasulo_summary.md") `
    --csv (Join-Path $ReportPerfDir "tomasulo_summary.csv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: Tomasulo report generation failed"
}

foreach ($RequiredFile in @(
    (Join-Path $ReportSimDir "tomasulo_trace.log"),
    (Join-Path $ReportPerfDir "tomasulo_summary.md"),
    (Join-Path $ReportPerfDir "tomasulo_summary.csv")
)) {
    if (-not (Test-Path $RequiredFile)) {
        throw "FAIL: required Tomasulo artifact missing: $RequiredFile"
    }
}

Write-Host "PASS: Phase 17 Tomasulo-style validation and reports completed."
