param(
    [int]$Seed = 1,
    [int]$Count = 50,
    [switch]$SkipLint,
    [switch]$SkipSynth
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $reportSimDir | Out-Null
$summary = Join-Path $reportSimDir "pipeline_tests_summary.log"
"Phase 5 pipeline verification run $(Get-Date -Format s)" | Set-Content -Path $summary

function Invoke-Step {
    param(
        [string]$Name,
        [string]$Script,
        [string[]]$Args = @()
    )
    Add-Content -Path $summary -Value "RUN $Name"
    Write-Host "== $Name =="
    $output = powershell -ExecutionPolicy Bypass -File $Script @Args 2>&1
    $output | Tee-Object -FilePath (Join-Path $reportSimDir ($Name + ".log"))
    if ($LASTEXITCODE -ne 0) {
        Add-Content -Path $summary -Value "FAIL $Name"
        throw "$Name failed"
    }
    if ($output -match "FAIL:") {
        Add-Content -Path $summary -Value "FAIL $Name reported FAIL"
        throw "$Name reported FAIL"
    }
    Add-Content -Path $summary -Value "PASS $Name"
}

Push-Location $root
try {
    Invoke-Step "phase1_single_cycle" ".\scripts\run_sim.ps1"
    Invoke-Step "phase2_single_cycle" ".\scripts\run_phase2_sim.ps1"
    Invoke-Step "phase3_single_cycle" ".\scripts\run_phase3_sim.ps1"
    Invoke-Step "phase4_pipeline" ".\scripts\run_phase4_sim.ps1"
    Invoke-Step "phase5_trace" ".\scripts\run_phase5_trace.ps1"
    Invoke-Step "phase5_random" ".\scripts\run_phase5_random.ps1" @("-Seed", "$Seed", "-Count", "$Count")
    if (-not $SkipLint) {
        Invoke-Step "phase5_lint" ".\scripts\run_phase5_lint.ps1"
    }
    if (-not $SkipSynth) {
        Invoke-Step "phase5_synth" ".\scripts\run_phase5_synth.ps1"
    }
    Add-Content -Path $summary -Value "OVERALL PASS"
    Write-Host "OVERALL PASS"
    Write-Host "Summary: reports\sim\pipeline_tests_summary.log"
} catch {
    Add-Content -Path $summary -Value "OVERALL FAIL: $($_.Exception.Message)"
    Write-Host "OVERALL FAIL: $($_.Exception.Message)"
    throw
} finally {
    Pop-Location
}



