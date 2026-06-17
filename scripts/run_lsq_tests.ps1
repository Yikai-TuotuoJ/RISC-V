param(
    [switch]$SkipPriorRegressions
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "lsq_logs"
$SimLog = Join-Path $LogDir "lsq_validation.log"
$Exe = Join-Path $SimDir "tb_lsq_experiment.vvp"

New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null

if (-not $SkipPriorRegressions) {
    Write-Host "Running prior ROB regression reference..."
    & (Join-Path $PSScriptRoot "run_rob_tests.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: prior ROB regression failed"
    }
}

Write-Host "Compiling Phase 19 LSQ validation..."
& iverilog -g2012 -Wall -s tb_lsq_experiment -o $Exe `
    (Join-Path $Root "rtl\tomasulo_rob_lsq_experiment_core.sv") `
    (Join-Path $Root "tb\tb_lsq_experiment.sv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: LSQ compile failed"
}

Write-Host "Running Phase 19 LSQ validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: LSQ simulation failed"
    }
} finally {
    Pop-Location
}

Write-Host "Generating Phase 19 LSQ reports..."
& python3 (Join-Path $PSScriptRoot "summarize_lsq_reports.py") `
    --log $SimLog `
    --markdown (Join-Path $ReportPerfDir "lsq_summary.md") `
    --csv (Join-Path $ReportPerfDir "lsq_summary.csv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: LSQ report generation failed"
}

foreach ($RequiredFile in @(
    (Join-Path $ReportSimDir "lsq_trace.log"),
    (Join-Path $ReportPerfDir "lsq_summary.md"),
    (Join-Path $ReportPerfDir "lsq_summary.csv")
)) {
    if (-not (Test-Path $RequiredFile)) {
        throw "FAIL: required LSQ artifact missing: $RequiredFile"
    }
}

Write-Host "PASS: Phase 19 LSQ validation and reports completed."
