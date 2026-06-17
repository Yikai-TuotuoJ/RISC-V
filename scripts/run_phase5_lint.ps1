param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$log = Join-Path $reportDir "lint_phase5.log"

Push-Location $root
try {
    if (Test-Path $env:PYTHON_EXECUTABLE) {
        & $env:PYTHON_EXECUTABLE .\scripts\gen_random_pipeline_test.py --seed 1 --count 50 --compat 2>&1 | Tee-Object -FilePath $log
    } else {
        powershell -ExecutionPolicy Bypass -File .\scripts\gen_phase5_random.ps1 2>&1 | Tee-Object -FilePath $log
    }
    verilator_bin --lint-only --timing --top-module tb_rv32i_pipeline_core_phase5_trace -Wall --Wno-fatal --Wno-UNUSEDSIGNAL --Wno-PINMISSING rtl/alu.sv rtl/decoder.sv rtl/regfile.sv rtl/imem.sv rtl/dmem_stub.sv rtl/branch_predictor.sv rtl/gshare_branch_predictor.sv rtl/direct_mapped_dcache.sv rtl/rv32i_pipeline_core.sv tb/tb_rv32i_pipeline_core_phase5_trace.sv 2>&1 | Tee-Object -FilePath $log -Append
    verilator_bin --lint-only --timing --top-module tb_rv32i_pipeline_core_phase5_random -Wall --Wno-fatal --Wno-UNUSEDSIGNAL --Wno-PINMISSING rtl/alu.sv rtl/decoder.sv rtl/regfile.sv rtl/imem.sv rtl/dmem_stub.sv rtl/branch_predictor.sv rtl/gshare_branch_predictor.sv rtl/direct_mapped_dcache.sv rtl/rv32i_pipeline_core.sv tb/tb_rv32i_pipeline_core_phase5_random.sv 2>&1 | Tee-Object -FilePath $log -Append
} finally {
    Pop-Location
}







