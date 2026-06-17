$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$ReportDir = Join-Path $Root "reports\lint"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$Log = Join-Path $ReportDir "final_cpu_verilator_lint.log"
Write-Host "Running Verilator lint for Phase 21 final CPU..."
& verilator_bin --lint-only --timing -Wno-fatal -Wno-DECLFILENAME -Wno-BLKSEQ -Wno-WIDTH `
    (Join-Path $Root "rtl\gshare_branch_predictor.sv") `
    (Join-Path $Root "rtl\rv32i_final_cpu_top.sv") 2>&1 | Tee-Object -FilePath $Log
if ($LASTEXITCODE -ne 0) { throw "FAIL: final CPU Verilator lint failed" }
Write-Host "PASS: final CPU Verilator lint completed."

