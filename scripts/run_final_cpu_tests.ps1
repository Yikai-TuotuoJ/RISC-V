param(
    [switch]$SkipPriorRegressions
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$SimDir = Join-Path $Root "sim"
$ReportSimDir = Join-Path $Root "reports\sim"
$ReportPerfDir = Join-Path $Root "reports\perf"
$LogDir = Join-Path $ReportPerfDir "final_cpu_logs"
$SimLog = Join-Path $LogDir "final_cpu_validation.log"
$Exe = Join-Path $SimDir "tb_final_cpu.vvp"
New-Item -ItemType Directory -Force -Path $SimDir, $ReportSimDir, $ReportPerfDir, $LogDir | Out-Null

$TopText = Get-Content -LiteralPath (Join-Path $Root "rtl\rv32i_final_cpu_top.sv") -Raw
$Header = [regex]::Match($TopText, 'module\s+rv32i_final_cpu_top[\s\S]*?;').Value
if ($Header -match '(debug|scoreboard|trace_|perf_|rob_|rs_|lsq_)') {
    throw "FAIL: final CPU top-level header exposes a debug/scoreboard-only public interface"
}

if (-not $SkipPriorRegressions) {
    Write-Host "Running Phase 20 OOO reference regression..."
    & (Join-Path $PSScriptRoot "run_ooo_tests.ps1") -SkipPriorRegressions
    if ($LASTEXITCODE -ne 0) { throw "FAIL: Phase 20 OOO reference regression failed" }
    Write-Host "Running Phase 15 SMT reference regression..."
    & (Join-Path $PSScriptRoot "run_smt_tests.ps1") -SkipPriorRegressions
    if ($LASTEXITCODE -ne 0) { throw "FAIL: Phase 15 SMT reference regression failed" }
}

Write-Host "Compiling Phase 21 final CPU validation..."
& iverilog -g2012 -Wall -s tb_final_cpu_uvm_style -o $Exe `
    (Join-Path $Root "rtl\gshare_branch_predictor.sv") `
    (Join-Path $Root "rtl\rv32i_final_cpu_top.sv") `
    (Join-Path $Root "tb\tb_final_cpu_uvm_style.sv")
if ($LASTEXITCODE -ne 0) { throw "FAIL: final CPU compile failed" }

Write-Host "Running Phase 21 final CPU validation..."
Push-Location $Root
try {
    & vvp $Exe 2>&1 | Tee-Object -FilePath $SimLog
    if ($LASTEXITCODE -ne 0) { throw "FAIL: final CPU simulation failed" }
} finally { Pop-Location }

$LogText = Get-Content -LiteralPath $SimLog -Raw
if ($LogText -notmatch 'PASS: Phase 21 final CPU validation') { throw "FAIL: final CPU simulation did not print PASS" }
if ($LogText -match 'FAIL:') { throw "FAIL: final CPU simulation log contains FAIL" }
$Perf = [regex]::Match($LogText, 'FINALPERF:.*checks=(\d+).*errors=(\d+)')
if (-not $Perf.Success) { throw "FAIL: FINALPERF line missing" }
if ([int]$Perf.Groups[1].Value -lt 60) { throw "FAIL: fewer than 60 final CPU checks executed" }
if ([int]$Perf.Groups[2].Value -ne 0) { throw "FAIL: final CPU reported nonzero errors" }

foreach ($RequiredFile in @(
    (Join-Path $ReportPerfDir "final_cpu_summary.md"),
    (Join-Path $ReportPerfDir "final_cpu_summary.csv"),
    (Join-Path $ReportPerfDir "final_cpu_cache_ucp_summary.md"),
    (Join-Path $ReportSimDir "final_cpu_trace.log"),
    (Join-Path $SimDir "final_cpu.vcd")
)) {
    if (-not (Test-Path -LiteralPath $RequiredFile)) { throw "FAIL: required final CPU artifact missing: $RequiredFile" }
}
Write-Host "PASS: Phase 21 final CPU validation and reports completed."
