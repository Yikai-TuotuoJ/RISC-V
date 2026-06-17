$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$ReportDir = Join-Path $Root "reports\synth"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$Log = Join-Path $ReportDir "final_cpu_yosys.log"
Write-Host "Running Yosys synthesis sanity for Phase 21 final CPU..."
Push-Location $Root
try {
    & yosys -s "synth\synth_final_cpu.ys" 2>&1 | Tee-Object -FilePath $Log
    if ($LASTEXITCODE -ne 0) { throw "FAIL: final CPU Yosys synthesis failed" }
} finally { Pop-Location }
Write-Host "PASS: final CPU Yosys synthesis sanity completed."
