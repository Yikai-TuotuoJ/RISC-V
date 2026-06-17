param(
    [switch]$SkipRegression,
    [switch]$SkipCacheHierarchy,
    [switch]$SkipTraceModel,
    [switch]$SkipRtl
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$perfDir = Join-Path $root "reports\perf"
$traceLogDir = Join-Path $perfDir "ucp_logs"
$rtlLogDir = Join-Path $perfDir "ucp_rtl_logs"
$simReportDir = Join-Path $root "reports\sim"
$simDir = Join-Path $root "sim"
New-Item -ItemType Directory -Force -Path $perfDir, $traceLogDir, $rtlLogDir, $simReportDir, $simDir | Out-Null
$ucpTracePath = Join-Path $simReportDir "ucp_rtl_trace.log"
if (Test-Path -LiteralPath $ucpTracePath) { Remove-Item -LiteralPath $ucpTracePath -Force }
$failed = $false
Push-Location $root
try {
    if (-not $SkipRegression) {
        Write-Host "== pipeline regression =="
        & $PSScriptRoot\run_pipeline_tests.ps1 -SkipLint -SkipSynth
        if ($LASTEXITCODE -ne 0) { throw "Pipeline regression failed" }
    }
    if (-not $SkipCacheHierarchy) {
        Write-Host "== Phase 12 cache hierarchy regression =="
        & $PSScriptRoot\run_cache_hierarchy_tests.ps1 -SkipRegression -SkipPhase11
        if ($LASTEXITCODE -ne 0) { throw "Cache hierarchy regression failed" }
    }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $cmd = Get-Command python -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source }
    }
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        Write-Host "FAIL: python was not found"
        exit 1
    }

    if (-not $SkipTraceModel) {
        Write-Host "== UCP-style trace policy model =="
        & $python .\scripts\ucp_partition_model.py --trace-dir .\tests\benchmarks\ucp --out-dir .\reports\perf --total-lines 4 --line-bytes 4 --miss-penalty 10
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }

    if (-not $SkipRtl) {
        Write-Host "== UCP RTL cache hierarchy tests =="
        Remove-Item -LiteralPath (Join-Path $rtlLogDir "*.log") -Force -ErrorAction SilentlyContinue
        $rtl = @(
            "rtl/alu.sv", "rtl/decoder.sv", "rtl/regfile.sv", "rtl/imem.sv", "rtl/dmem_stub.sv",
            "rtl/branch_predictor.sv", "rtl/gshare_branch_predictor.sv", "rtl/direct_mapped_dcache.sv",
            "rtl/rv32i_pipeline_core.sv", "tb/tb_rv32i_pipeline_ucp_cache.sv"
        )
        $configs = @(
            @{ Name = "l2_reuse_equal"; Policy = 0; L2Lines = 4; Interval = 8; Out = "sim\phase13_5_ucp_l2reuse.vvp"; Benches = @(@{Name="shared_l2_reuse"; Id=50; Hex="tests/benchmarks/ucp_rtl/shared_l2_reuse.hex"; EndPc=48}) },
            @{ Name = "l3_equal"; Policy = 0; L2Lines = 2; Interval = 8; Out = "sim\phase13_5_ucp_equal.vvp"; Benches = @(@{Name="l3_reuse_after_l2_eviction"; Id=51; Hex="tests/benchmarks/ucp_rtl/l3_reuse_after_l2_eviction.hex"; EndPc=64}, @{Name="utility_pressure"; Id=52; Hex="tests/benchmarks/ucp_rtl/utility_pressure.hex"; EndPc=104}) },
            @{ Name = "l3_utility"; Policy = 1; L2Lines = 2; Interval = 8; Out = "sim\phase13_5_ucp_utility.vvp"; Benches = @(@{Name="utility_pressure"; Id=52; Hex="tests/benchmarks/ucp_rtl/utility_pressure.hex"; EndPc=104}) },
            @{ Name = "l3_dynamic"; Policy = 2; L2Lines = 2; Interval = 8; Out = "sim\phase13_6_ucp_dynamic.vvp"; Benches = @(@{Name="utility_pressure"; Id=52; Hex="tests/benchmarks/ucp_rtl/utility_pressure.hex"; EndPc=104}) }
        )
        foreach ($config in $configs) {
            iverilog -g2012 -Wall -s tb_rv32i_pipeline_ucp_cache "-Ptb_rv32i_pipeline_ucp_cache.L3_UCP_POLICY=$($config.Policy)" "-Ptb_rv32i_pipeline_ucp_cache.L2_LINES=$($config.L2Lines)" "-Ptb_rv32i_pipeline_ucp_cache.UCP_REPARTITION_INTERVAL=$($config.Interval)" -o $config.Out $rtl
            foreach ($bench in $config.Benches) {
                Write-Host "== UCP RTL $($bench.Name) config=$($config.Name) =="
                $log = Join-Path $rtlLogDir ("{0}_{1}.log" -f $bench.Name, $config.Name)
                $simOutput = vvp $config.Out "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
                $simOutput | ForEach-Object { Write-Host $_ }
                $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
                $text = ($simOutput | Out-String)
                if ($text -match "FAIL:" -or $text -notmatch "UCPRTL:") {
                    Write-Host "FAIL: UCP RTL $($bench.Name) config=$($config.Name)"
                    $failed = $true
                } else {
                    Write-Host "PASS: UCP RTL $($bench.Name) config=$($config.Name)"
                }
            }
        }
        & $python .\scripts\summarize_ucp_rtl_reports.py
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }
} finally {
    Pop-Location
}
if ($failed) { exit 1 }
Write-Host "PASS: Phase 13.6 dynamic UCP RTL flow completed"
Write-Host "Trace model summary: reports\perf\ucp_partition_summary.md"
Write-Host "RTL summary: reports\perf\ucp_rtl_partition_summary.md"
Write-Host "RTL CSV: reports\perf\ucp_rtl_partition_summary.csv"
Write-Host "RTL trace: reports\sim\ucp_rtl_trace.log"
