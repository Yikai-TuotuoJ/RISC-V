param(
    [switch]$SkipPriorRegressions
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "scoreboard_logs"
$SimLog = Join-Path $LogDir "scoreboard_validation.log"
$Exe = Join-Path $SimDir "tb_scoreboard.vvp"

New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null

if (-not $SkipPriorRegressions) {
    Write-Host "Running prior SMT/cache/UCP regression reference..."
    & (Join-Path $PSScriptRoot "run_smt_tests.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: prior SMT/cache/UCP regression failed"
    }
}

Write-Host "Compiling Phase 16 scoreboard validation..."
& iverilog -g2012 -Wall -s tb_scoreboard -o $Exe `
    (Join-Path $Root "rtl\reservation_station_entry.sv") `
    (Join-Path $Root "rtl\scoreboard_issue_model.sv") `
    (Join-Path $Root "tb\tb_scoreboard.sv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: scoreboard compile failed"
}

Write-Host "Running Phase 16 scoreboard validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) {
        throw "FAIL: scoreboard simulation failed"
    }
} finally {
    Pop-Location
}

Write-Host "Generating Phase 16 scoreboard reports..."
& python3 (Join-Path $PSScriptRoot "summarize_scoreboard_reports.py") `
    --log $SimLog `
    --markdown (Join-Path $ReportPerfDir "scoreboard_summary.md") `
    --csv (Join-Path $ReportPerfDir "scoreboard_summary.csv")
if ($LASTEXITCODE -ne 0) {
    throw "FAIL: scoreboard report generation failed"
}

$Trace = Join-Path $ReportSimDir "scoreboard_trace.log"
$Markdown = Join-Path $ReportPerfDir "scoreboard_summary.md"
$Csv = Join-Path $ReportPerfDir "scoreboard_summary.csv"
foreach ($RequiredFile in @($Trace, $Markdown, $Csv)) {
    if (-not (Test-Path $RequiredFile)) {
        throw "FAIL: required scoreboard artifact missing: $RequiredFile"
    }
}

Write-Host "PASS: Phase 16 scoreboard validation and reports completed."
