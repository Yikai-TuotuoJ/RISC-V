param(
    [switch]$SkipPriorRegressions
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. $PSScriptRoot\setup_oss_cad_env.ps1
$simDir = Join-Path $root "sim"
$simReportDir = Join-Path $root "reports\sim"
$perfDir = Join-Path $root "reports\perf"
$logDir = Join-Path $perfDir "smt_logs"
New-Item -ItemType Directory -Force -Path $simDir, $simReportDir, $perfDir, $logDir | Out-Null
Remove-Item -Path (Join-Path $logDir "*.log") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $simReportDir "smt_trace.log") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $simReportDir "smt_ucp_trace.log") -Force -ErrorAction SilentlyContinue

Push-Location $root
try {
    python3 .\scripts\gen_smt_tests.py

    if (-not $SkipPriorRegressions) {
        Write-Host "== prior pipeline/cache/UCP regression =="
        powershell -ExecutionPolicy Bypass -File .\scripts\run_phase14_ucp_validation.ps1
    }

    $rtl = @(
        "rtl\alu.sv",
        "rtl\decoder.sv",
        "rtl\imem.sv",
        "rtl\threaded_regfile.sv",
        "rtl\direct_mapped_dcache.sv",
        "rtl\rv32i_smt_pipeline_core.sv",
        "tb\tb_rv32i_smt_pipeline_core.sv"
    )

    $tests = @(
        @{ Name="context_basic"; Id=1; Policy=2; Ret0=5; Ret1=4; Cache=0; L2=0; L3=0 },
        @{ Name="hazard_memory"; Id=2; Policy=2; Ret0=6; Ret1=6; Cache=0; L2=0; L3=0 },
        @{ Name="branch_jump"; Id=3; Policy=2; Ret0=5; Ret1=4; Cache=0; L2=0; L3=0 },
        @{ Name="smt_ucp_balanced"; Id=5; Policy=0; Ret0=9; Ret1=9; Cache=1; L2=1; L3=1 },
        @{ Name="smt_ucp_hot_stream"; Id=4; Policy=1; Ret0=13; Ret1=13; Cache=1; L2=1; L3=1 },
        @{ Name="smt_ucp_hot_stream"; Id=4; Policy=2; Ret0=13; Ret1=13; Cache=1; L2=1; L3=1 }
    )

    $totalChecks = 0
    foreach ($t in $tests) {
        $exe = Join-Path $simDir ("phase15_{0}_p{1}.vvp" -f $t.Name, $t.Policy)
        $log = Join-Path $logDir ("{0}_policy{1}.log" -f $t.Name, $t.Policy)
        Write-Host ("== SMT {0} policy {1} ==" -f $t.Name, $t.Policy)
        & iverilog -g2012 -s tb_rv32i_smt_pipeline_core `
            "-Ptb_rv32i_smt_pipeline_core.L3_UCP_POLICY=$($t.Policy)" `
            "-Ptb_rv32i_smt_pipeline_core.DCACHE_ENABLE=$($t.Cache)" `
            "-Ptb_rv32i_smt_pipeline_core.L2_ENABLE=$($t.L2)" `
            "-Ptb_rv32i_smt_pipeline_core.L3_ENABLE=$($t.L3)" `
            -o $exe @rtl
        if ($LASTEXITCODE -ne 0) { throw "iverilog compile failed for $($t.Name) policy $($t.Policy)" }
        $hex0 = "tests/benchmarks/smt/$($t.Name)_t0.hex"
        $hex1 = "tests/benchmarks/smt/$($t.Name)_t1.hex"
        $output = & vvp $exe "+BENCH=$($t.Name)" "+BENCH_ID=$($t.Id)" "+HEX0=$hex0" "+HEX1=$hex1" "+EXP_RET0=$($t.Ret0)" "+EXP_RET1=$($t.Ret1)" 2>&1
        $output | Tee-Object -FilePath $log
        if ($LASTEXITCODE -ne 0) { throw "vvp failed for $($t.Name) policy $($t.Policy)" }
        if ($output -match "FAIL:") { throw "simulation reported FAIL for $($t.Name) policy $($t.Policy)" }
        foreach ($line in $output) {
            if ($line -match "SMT_TESTS:.*checks=([0-9]+)") {
                $totalChecks += [int]$Matches[1]
            }
        }
    }

    if ($totalChecks -lt 20) {
        throw "Only $totalChecks meaningful SMT checks ran; Phase 15 requires at least 20"
    }

    python3 .\scripts\summarize_smt_reports.py
    python3 .\scripts\check_smt_counter_consistency.py

    if (-not (Test-Path (Join-Path $perfDir "smt_summary.md"))) { throw "Missing smt_summary.md" }
    if (-not (Test-Path (Join-Path $perfDir "smt_summary.csv"))) { throw "Missing smt_summary.csv" }
    if (-not (Test-Path (Join-Path $perfDir "smt_ucp_summary.md"))) { throw "Missing smt_ucp_summary.md" }
    if (-not (Test-Path (Join-Path $perfDir "smt_ucp_summary.csv"))) { throw "Missing smt_ucp_summary.csv" }
    if (-not (Test-Path (Join-Path $simReportDir "smt_trace.log"))) { throw "Missing smt_trace.log" }
    if (-not (Test-Path (Join-Path $simReportDir "smt_ucp_trace.log"))) { throw "Missing smt_ucp_trace.log" }

    Write-Host "OVERALL PASS"
    Write-Host "SMT checks: $totalChecks"
    Write-Host "Reports: reports\perf\smt_summary.md, reports\perf\smt_ucp_summary.md"
} catch {
    Write-Host "OVERALL FAIL: $($_.Exception.Message)"
    throw
} finally {
    Pop-Location
}
