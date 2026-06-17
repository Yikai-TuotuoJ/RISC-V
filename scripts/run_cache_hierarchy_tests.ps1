param(
    [switch]$SkipRegression,
    [switch]$SkipPhase11,
    [switch]$SkipCompile
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$perfDir = Join-Path $root "reports\perf"
$logDir = Join-Path $perfDir "cache_hierarchy_logs"
$reportSimDir = Join-Path $root "reports\sim"
New-Item -ItemType Directory -Force -Path $simDir, $perfDir, $logDir, $reportSimDir | Out-Null
$tracePath = Join-Path $reportSimDir "cache_hierarchy_trace.log"
if (Test-Path -LiteralPath $tracePath) { Remove-Item -LiteralPath $tracePath -Force }
$rtl = @(
    "rtl/alu.sv", "rtl/decoder.sv", "rtl/regfile.sv", "rtl/imem.sv", "rtl/dmem_stub.sv",
    "rtl/branch_predictor.sv", "rtl/gshare_branch_predictor.sv", "rtl/direct_mapped_dcache.sv",
    "rtl/rv32i_pipeline_core.sv", "tb/tb_rv32i_pipeline_cache_hierarchy.sv"
)
$configs = @(
    @{ Name = "disabled"; L1 = 0; L2 = 0; L2Penalty = 6 },
    @{ Name = "l1_only"; L1 = 1; L2 = 0; L2Penalty = 6 },
    @{ Name = "l1_l2_p6"; L1 = 1; L2 = 1; L2Penalty = 6 },
    @{ Name = "l1_l2_p10"; L1 = 1; L2 = 1; L2Penalty = 10 }
)
$benchmarks = @(
    @{ Name = "repeated_l1_hit"; Id = 30; Hex = "tests/benchmarks/cache_hierarchy/repeated_l1_hit.hex"; EndPc = 40 },
    @{ Name = "l1_conflict_l2_hit"; Id = 31; Hex = "tests/benchmarks/cache_hierarchy/l1_conflict_l2_hit.hex"; EndPc = 40 },
    @{ Name = "store_load_policy_check"; Id = 32; Hex = "tests/benchmarks/cache_hierarchy/store_load_policy_check.hex"; EndPc = 40 },
    @{ Name = "mixed_l1_l2_program"; Id = 33; Hex = "tests/benchmarks/cache_hierarchy/mixed_l1_l2_program.hex"; EndPc = 40 }
)
$failed = $false
Push-Location $root
try {
    if (-not $SkipRegression) { & $PSScriptRoot\run_pipeline_tests.ps1 -SkipLint -SkipSynth; if ($LASTEXITCODE -ne 0) { throw "Pipeline regression failed" } }
    if (-not $SkipPhase11) { & $PSScriptRoot\run_cache_tests.ps1 -SkipRegression; if ($LASTEXITCODE -ne 0) { throw "Phase 11 cache regression failed" } }
    foreach ($config in $configs) {
        $out = Join-Path $simDir ("phase12_cache_hierarchy_{0}.vvp" -f $config.Name)
        if (-not $SkipCompile) {
            iverilog -g2012 -Wall -s tb_rv32i_pipeline_cache_hierarchy "-Ptb_rv32i_pipeline_cache_hierarchy.DCACHE_ENABLE=$($config.L1)" "-Ptb_rv32i_pipeline_cache_hierarchy.L2_ENABLE=$($config.L2)" "-Ptb_rv32i_pipeline_cache_hierarchy.L2_MISS_PENALTY=$($config.L2Penalty)" -o $out $rtl
        }
        foreach ($bench in $benchmarks) {
            $log = Join-Path $logDir ("{0}_{1}.log" -f $bench.Name, $config.Name)
            Write-Host "== cache hierarchy benchmark $($bench.Name) config=$($config.Name) =="
            $simOutput = vvp $out "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
            $simOutput | ForEach-Object { Write-Host $_ }
            $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
            $text = ($simOutput | Out-String)
            if ($text -match "FAIL:" -or $text -notmatch "HIERPERF:") { $failed = $true; Write-Host "FAIL: cache hierarchy benchmark $($bench.Name) config=$($config.Name)" }
            else { Write-Host "PASS: cache hierarchy benchmark $($bench.Name) config=$($config.Name)" }
        }
    }
    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) { $cmd = Get-Command python -ErrorAction SilentlyContinue; if ($cmd) { $python = $cmd.Source } }
    if (-not $python -or -not (Test-Path -LiteralPath $python)) { $failed = $true; Write-Host "FAIL: python was not found" }
    else { & $python .\scripts\summarize_cache_hierarchy_reports.py; if ($LASTEXITCODE -ne 0) { $failed = $true } }
} finally { Pop-Location }
if ($failed) { exit 1 }
Write-Host "PASS: Phase 12 cache hierarchy flow completed"
Write-Host "Summary Markdown: reports\perf\cache_hierarchy_summary.md"
Write-Host "Summary CSV: reports\perf\cache_hierarchy_summary.csv"
Write-Host "Cache hierarchy trace: reports\sim\cache_hierarchy_trace.log"
