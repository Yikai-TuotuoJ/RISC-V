param(
    [switch]$SkipRegressions,
    [switch]$SkipLint,
    [switch]$SkipSynth
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root "reports\phase14_ucp"
$logDir = Join-Path $reportDir "logs"
$simDir = Join-Path $root "sim"
New-Item -ItemType Directory -Force -Path $reportDir, $logDir, $simDir | Out-Null
Remove-Item -LiteralPath (Join-Path $logDir "*.log") -Force -ErrorAction SilentlyContinue
$traceSrc = Join-Path $root "reports\sim\ucp_rtl_trace.log"
$traceDst = Join-Path $reportDir "ucp_trace.log"
if (Test-Path -LiteralPath $traceSrc) { Remove-Item -LiteralPath $traceSrc -Force }
if (Test-Path -LiteralPath $traceDst) { Remove-Item -LiteralPath $traceDst -Force }
$failed = $false
Push-Location $root
try {
    if (-not $SkipRegressions) {
        Write-Host "== Phase 14 prerequisite: single-cycle regression =="
        & $PSScriptRoot\run_sim.ps1
        if ($LASTEXITCODE -ne 0) { throw "single-cycle regression failed" }

        Write-Host "== Phase 14 prerequisite: pipeline regression =="
        & $PSScriptRoot\run_pipeline_tests.ps1 -SkipLint -SkipSynth
        if ($LASTEXITCODE -ne 0) { throw "pipeline regression failed" }

        Write-Host "== Phase 14 prerequisite: gshare regression =="
        & $PSScriptRoot\run_gshare_tests.ps1 -SkipRegression
        if ($LASTEXITCODE -ne 0) { throw "gshare regression failed" }

        Write-Host "== Phase 14 prerequisite: memory-latency regression =="
        & $PSScriptRoot\run_memory_latency_tests.ps1 -SkipRegression
        if ($LASTEXITCODE -ne 0) { throw "memory-latency regression failed" }

        Write-Host "== Phase 14 prerequisite: direct-mapped cache regression =="
        & $PSScriptRoot\run_cache_tests.ps1 -SkipRegression
        if ($LASTEXITCODE -ne 0) { throw "direct-mapped cache regression failed" }

        Write-Host "== Phase 14 prerequisite: Phase 12 cache hierarchy regression =="
        & $PSScriptRoot\run_cache_hierarchy_tests.ps1 -SkipRegression -SkipPhase11
        if ($LASTEXITCODE -ne 0) { throw "cache hierarchy regression failed" }

        Write-Host "== Phase 14 prerequisite: Phase 13.5/13.6 UCP regression =="
        & $PSScriptRoot\run_ucp_tests.ps1 -SkipRegression -SkipCacheHierarchy -SkipTraceModel
        if ($LASTEXITCODE -ne 0) { throw "UCP regression failed" }
        if (Test-Path -LiteralPath $traceSrc) { Remove-Item -LiteralPath $traceSrc -Force }
    }

    Write-Host "== Phase 14 active UCP policy validation =="
    $rtl = @(
        "rtl/alu.sv", "rtl/decoder.sv", "rtl/regfile.sv", "rtl/imem.sv", "rtl/dmem_stub.sv",
        "rtl/branch_predictor.sv", "rtl/gshare_branch_predictor.sv", "rtl/direct_mapped_dcache.sv",
        "rtl/rv32i_pipeline_core.sv", "tb/tb_rv32i_pipeline_ucp_cache.sv"
    )
    $benches = @(
        @{Name="shared_l2_reuse"; Id=50; Hex="tests/benchmarks/ucp_rtl/shared_l2_reuse.hex"; EndPc=48; L2Lines=4},
        @{Name="l3_reuse_after_l2_eviction"; Id=51; Hex="tests/benchmarks/ucp_rtl/l3_reuse_after_l2_eviction.hex"; EndPc=64; L2Lines=2},
        @{Name="utility_pressure"; Id=52; Hex="tests/benchmarks/ucp_rtl/utility_pressure.hex"; EndPc=104; L2Lines=2},
        @{Name="dynamic_ucp_long_stream1"; Id=53; Hex="tests/benchmarks/ucp_rtl/dynamic_ucp_long_stream1.hex"; EndPc=304; L2Lines=2}
    )
    $modes = @(
        @{Name="mode0_l3_disabled"; L3Enable=0; UcpEnable=0; Policy=0; L2Lines=2; Out="sim\phase14_mode0_l3_disabled.vvp"},
        @{Name="mode1_l3_unpartitioned"; L3Enable=1; UcpEnable=0; Policy=0; L2Lines=2; Out="sim\phase14_mode1_l3_unpartitioned.vvp"},
        @{Name="mode2_l3_equal"; L3Enable=1; UcpEnable=1; Policy=0; L2Lines=2; Out="sim\phase14_mode2_l3_equal.vvp"},
        @{Name="mode3_l3_utility_fixed"; L3Enable=1; UcpEnable=1; Policy=1; L2Lines=2; Out="sim\phase14_mode3_l3_utility_fixed.vvp"},
        @{Name="mode4_dynamic_ucp"; L3Enable=1; UcpEnable=1; Policy=2; L2Lines=2; Out="sim\phase14_mode4_dynamic_ucp.vvp"}
    )
    foreach ($mode in $modes) {
        foreach ($bench in $benches) {
            $outFile = "sim\phase14_{0}_{1}.vvp" -f $bench.Name, $mode.Name
            iverilog -g2012 -Wall -s tb_rv32i_pipeline_ucp_cache `
                "-Ptb_rv32i_pipeline_ucp_cache.L3_ENABLE=$($mode.L3Enable)" `
                "-Ptb_rv32i_pipeline_ucp_cache.L3_UCP_ENABLE=$($mode.UcpEnable)" `
                "-Ptb_rv32i_pipeline_ucp_cache.L3_UCP_POLICY=$($mode.Policy)" `
                "-Ptb_rv32i_pipeline_ucp_cache.L2_LINES=$($bench.L2Lines)" `
                "-Ptb_rv32i_pipeline_ucp_cache.UCP_REPARTITION_INTERVAL=8" `
                -o $outFile $rtl
            if ($LASTEXITCODE -ne 0) { throw "Icarus compile failed for $($mode.Name) $($bench.Name)" }
            Write-Host "== Phase 14 $($bench.Name) $($mode.Name) =="
            $log = Join-Path $logDir ("{0}_{1}.log" -f $bench.Name, $mode.Name)
            $simOutput = vvp $outFile "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
            $simOutput | ForEach-Object { Write-Host $_ }
            $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
            $text = ($simOutput | Out-String)
            if ($text -match "FAIL:" -or $text -notmatch "UCPRTL:") {
                Write-Host "FAIL: Phase 14 $($bench.Name) $($mode.Name)"
                $failed = $true
            }
        }
    }
    if (Test-Path -LiteralPath $traceSrc) { Copy-Item -LiteralPath $traceSrc -Destination $traceDst -Force }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $cmd = Get-Command python -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source }
    }
    if (-not $python -or -not (Test-Path -LiteralPath $python)) { throw "python was not found" }
    & $python .\scripts\summarize_phase14_ucp.py
    if ($LASTEXITCODE -ne 0) { $failed = $true }

    $requiredReports = @(
        "reports\phase14_ucp\ucp_validation_summary.md",
        "reports\phase14_ucp\ucp_validation_summary.csv",
        "reports\phase14_ucp\ucp_policy_comparison.md",
        "reports\phase14_ucp\ucp_policy_comparison.csv",
        "reports\phase14_ucp\ucp_counter_consistency.md",
        "reports\phase14_ucp\ucp_trace.log"
    )
    foreach ($rel in $requiredReports) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $rel))) {
            Write-Host "FAIL: missing required report $rel"
            $failed = $true
        }
    }

    if (-not $SkipLint) {
        Write-Host "== Phase 14 lint sanity =="
        & $PSScriptRoot\run_lint.ps1
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
    if (-not $SkipSynth) {
        Write-Host "== Phase 14 synthesis sanity =="
        & $PSScriptRoot\run_synth.ps1
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
} finally {
    Pop-Location
}
if ($failed) { exit 1 }
Write-Host "PASS: Phase 14 active UCP validation completed"
Write-Host "Validation summary: reports\phase14_ucp\ucp_validation_summary.md"
Write-Host "Policy comparison: reports\phase14_ucp\ucp_policy_comparison.md"
Write-Host "Counter consistency: reports\phase14_ucp\ucp_counter_consistency.md"
Write-Host "Trace: reports\phase14_ucp\ucp_trace.log"




