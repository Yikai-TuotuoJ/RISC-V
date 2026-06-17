param(
    [switch]$SkipRegression,
    [switch]$SkipCompile
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$perfDir = Join-Path $root "reports\perf"
$logDir = Join-Path $perfDir "cache_logs"
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $simDir, $perfDir, $logDir, $reportSimDir | Out-Null
$tracePath = Join-Path $reportSimDir "cache_trace.log"
if (Test-Path -LiteralPath $tracePath) { Remove-Item -LiteralPath $tracePath -Force }

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
    "tb/tb_rv32i_pipeline_cache.sv"
)

$configs = @(
    @{ Name = "disabled"; Enable = 0; Penalty = 3 },
    @{ Name = "enabled_p3"; Enable = 1; Penalty = 3 },
    @{ Name = "enabled_p5"; Enable = 1; Penalty = 5 }
)

$benchmarks = @(
    @{ Name = "repeated_load"; Id = 20; Hex = "tests/benchmarks/cache/repeated_load.hex"; EndPc = 40 },
    @{ Name = "store_load_check"; Id = 21; Hex = "tests/benchmarks/cache/store_load_check.hex"; EndPc = 40 },
    @{ Name = "conflict_loads"; Id = 22; Hex = "tests/benchmarks/cache/conflict_loads.hex"; EndPc = 40 },
    @{ Name = "mixed_cache_program"; Id = 23; Hex = "tests/benchmarks/cache/mixed_cache_program.hex"; EndPc = 40 }
)

$failed = $false
Push-Location $root
try {
    if (-not $SkipRegression) {
        Write-Host "== existing pipeline regression =="
        & $PSScriptRoot\run_pipeline_tests.ps1 -SkipLint -SkipSynth
        if ($LASTEXITCODE -ne 0) { throw "Pipeline regression failed" }
    }

    foreach ($config in $configs) {
        $out = Join-Path $simDir ("phase11_cache_{0}.vvp" -f $config.Name)
        if (-not $SkipCompile) {
            iverilog -g2012 -Wall -s tb_rv32i_pipeline_cache "-Ptb_rv32i_pipeline_cache.DCACHE_ENABLE=$($config.Enable)" "-Ptb_rv32i_pipeline_cache.DCACHE_MISS_PENALTY_CYCLES=$($config.Penalty)" -o $out $rtl
        }

        foreach ($bench in $benchmarks) {
            $log = Join-Path $logDir ("{0}_{1}.log" -f $bench.Name, $config.Name)
            Write-Host "== cache benchmark $($bench.Name) config=$($config.Name) =="
            $simOutput = vvp $out "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
            $simOutput | ForEach-Object { Write-Host $_ }
            $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
            $simText = ($simOutput | Out-String)
            if ($simText -match "FAIL:") {
                Write-Host "FAIL: cache benchmark $($bench.Name) config=$($config.Name)"
                $failed = $true
            } elseif ($simText -notmatch "CACHEPERF:") {
                Write-Host "FAIL: cache benchmark $($bench.Name) config=$($config.Name) did not emit CACHEPERF line"
                $failed = $true
            } else {
                Write-Host "PASS: cache benchmark $($bench.Name) config=$($config.Name)"
            }
        }
    }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd) { $python = $pythonCmd.Source }
    }
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        Write-Host "FAIL: python was not found, so cache summaries could not be generated"
        $failed = $true
    } else {
        & $python .\scripts\summarize_cache_reports.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: cache summary generation failed"
            $failed = $true
        }
    }
} finally {
    Pop-Location
}

if ($failed) { exit 1 }

Write-Host "PASS: Phase 11 cache flow completed"
Write-Host "Summary Markdown: reports\perf\cache_summary.md"
Write-Host "Summary CSV: reports\perf\cache_summary.csv"
Write-Host "Cache trace: reports\sim\cache_trace.log"
