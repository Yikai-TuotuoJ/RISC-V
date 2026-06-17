param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports\synth"
$netlistDir = Join-Path $reportDir "netlists"
$jsonDir = Join-Path $reportDir "json"
$dotDir = Join-Path $reportDir "dot"
$svgDir = Join-Path $reportDir "svg"
New-Item -ItemType Directory -Force -Path $reportDir, $netlistDir, $jsonDir, $dotDir, $svgDir | Out-Null

if (-not (Get-Command yosys -ErrorAction SilentlyContinue)) {
    Write-Host "FAIL: yosys was not found. Phase 8 synthesis reports require Yosys."
    exit 1
}

$variants = @(
    @{ Name = "single_cycle"; Script = "synth\synth_single_cycle.ys"; Log = "single_cycle_yosys.log" },
    @{ Name = "pipeline"; Script = "synth\synth_pipeline.ys"; Log = "pipeline_yosys.log" },
    @{ Name = "pipeline_gshare"; Script = "synth\synth_pipeline_gshare.ys"; Log = "pipeline_gshare_yosys.log" }
)

$failed = $false
Push-Location $root
try {
    foreach ($variant in $variants) {
        $logPath = Join-Path $reportDir $variant.Log
        Write-Host "== synth $($variant.Name) =="
        yosys -l $logPath -s $variant.Script
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: $($variant.Name) synthesis failed"
            $failed = $true
        } else {
            Write-Host "PASS: $($variant.Name) synthesis report generated"
        }
    }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd) {
            $python = $pythonCmd.Source
        }
    }

    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        Write-Host "FAIL: python was not found, so synthesis summaries could not be generated"
        $failed = $true
    } else {
        & $python .\scripts\summarize_synth_reports.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: synthesis summary generation failed"
            $failed = $true
        } else {
            Write-Host "PASS: synthesis summaries generated"
            Write-Host "Summary Markdown: reports\synth\synth_summary.md"
            Write-Host "Summary CSV: reports\synth\synth_summary.csv"
        }
    }
} finally {
    Pop-Location
}

if ($failed) {
    exit 1
}

Write-Host "PASS: Phase 8 synthesis report flow completed"



