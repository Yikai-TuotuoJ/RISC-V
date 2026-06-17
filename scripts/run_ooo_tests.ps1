param(
    [switch]$SkipPriorRegressions
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "ooo_logs"
$SimLog = Join-Path $LogDir "ooo_validation.log"
$Exe = Join-Path $SimDir "tb_ooo_experiment_core.vvp"
New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null
if (-not $SkipPriorRegressions) {
    Write-Host "Running prior LSQ regression reference..."
    & (Join-Path $PSScriptRoot "run_lsq_tests.ps1")
    if ($LASTEXITCODE -ne 0) { throw "FAIL: prior LSQ regression failed" }
}
Write-Host "Compiling Phase 20 integrated OOO validation..."
& iverilog -g2012 -Wall -s tb_ooo_experiment_core -o $Exe `
    (Join-Path $Root "rtl\ooo_experiment_core.sv") `
    (Join-Path $Root "tb\tb_ooo_experiment_core.sv")
if ($LASTEXITCODE -ne 0) { throw "FAIL: OOO compile failed" }
Write-Host "Running Phase 20 integrated OOO validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) { throw "FAIL: OOO simulation failed" }
} finally { Pop-Location }
Write-Host "Generating Phase 20 OOO reports..."
& python3 (Join-Path $PSScriptRoot "summarize_ooo_reports.py") `
    --log $SimLog `
    --markdown (Join-Path $ReportPerfDir "ooo_summary.md") `
    --csv (Join-Path $ReportPerfDir "ooo_summary.csv")
if ($LASTEXITCODE -ne 0) { throw "FAIL: OOO report generation failed" }
foreach ($RequiredFile in @(
    (Join-Path $ReportSimDir "ooo_trace.log"),
    (Join-Path $ReportPerfDir "ooo_summary.md"),
    (Join-Path $ReportPerfDir "ooo_summary.csv"),
    (Join-Path $SimDir "phase20_ooo.vcd")
)) { if (-not (Test-Path $RequiredFile)) { throw "FAIL: required OOO artifact missing: $RequiredFile" } }
Write-Host "PASS: Phase 20 integrated OOO validation and reports completed."
