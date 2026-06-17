param(
    [int]$Seed = 1,
    [int]$Count = 50
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $simDir | Out-Null
New-Item -ItemType Directory -Force -Path $reportSimDir | Out-Null

$rtl = @(
    "rtl/alu.sv",
    "rtl/decoder.sv",
    "rtl/regfile.sv",
    "rtl/imem.sv",
    "rtl/dmem_stub.sv",
    "rtl/branch_predictor.sv",
    "rtl/gshare_branch_predictor.sv",
    "rtl/direct_mapped_dcache.sv",
    "rtl/rv32i_pipeline_core.sv",
    "tb/tb_rv32i_pipeline_core_phase5_random.sv"
)
$out = Join-Path $simDir "phase5_random.vvp"
$log = Join-Path $reportSimDir "phase5_random.log"

Push-Location $root
try {
    if (Test-Path $env:PYTHON_EXECUTABLE) {
        & $env:PYTHON_EXECUTABLE .\scripts\gen_random_pipeline_test.py --seed $Seed --count $Count --compat | Tee-Object -FilePath $log
    } else {
        powershell -ExecutionPolicy Bypass -File .\scripts\gen_phase5_random.ps1 | Tee-Object -FilePath $log
    }
    iverilog -g2012 -Wall -o $out $rtl 2>&1 | Tee-Object -FilePath $log -Append
    $simOutput = vvp $out 2>&1
    $simOutput | Tee-Object -FilePath $log -Append
    $simOutput | ForEach-Object { Write-Host $_ }
    if ($simOutput -match "FAIL:") {
        throw "Phase 5 randomized simulation reported FAIL"
    }
    Write-Host "Random program: tests\generated\random_pipeline_seed$Seed.hex"
    Write-Host "Compatibility hex: tests\phase5_random.hex"
    Write-Host "Waveform: sim\phase5_random.vcd"
    Write-Host "Log: reports\sim\phase5_random.log"
} finally {
    Pop-Location
}






