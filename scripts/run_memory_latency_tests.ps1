param(
    [switch]$SkipRegression,
    [switch]$SkipCompile
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$perfDir = Join-Path $root "reports\perf"
$logDir = Join-Path $perfDir "memory_latency_logs"
New-Item -ItemType Directory -Force -Path $simDir, $perfDir, $logDir | Out-Null

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
    "tb/tb_rv32i_pipeline_mem_latency.sv"
)

$latencies = @(1, 3, 5)
$benchmarks = @(
    @{ Name = "mem_load_chain"; Id = 10; Hex = "tests/benchmarks/mem_load_chain.hex"; EndPc = 56 },
    @{ Name = "mem_store_load"; Id = 11; Hex = "tests/benchmarks/mem_store_load.hex"; EndPc = 64 },
    @{ Name = "mem_mixed_latency"; Id = 12; Hex = "tests/benchmarks/mem_mixed_latency.hex"; EndPc = 72 }
)

$failed = $false
Push-Location $root
try {
    if (-not $SkipRegression) {
        Write-Host "== existing pipeline regression =="
        & $PSScriptRoot\run_pipeline_tests.ps1 -SkipLint -SkipSynth
        if ($LASTEXITCODE -ne 0) { throw "Pipeline regression failed" }
    }

    foreach ($latency in $latencies) {
        $out = Join-Path $simDir ("phase10_memory_latency_{0}.vvp" -f $latency)
        if (-not $SkipCompile) {
            iverilog -g2012 -Wall -s tb_rv32i_pipeline_mem_latency "-Ptb_rv32i_pipeline_mem_latency.DMEM_LATENCY_CYCLES=$latency" -o $out $rtl
        }

        foreach ($bench in $benchmarks) {
            $log = Join-Path $logDir ("{0}_lat{1}.log" -f $bench.Name, $latency)
            Write-Host "== memory benchmark $($bench.Name) latency=$latency =="
            $simOutput = vvp $out "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
            $simOutput | ForEach-Object { Write-Host $_ }
            $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
            $simText = ($simOutput | Out-String)
            if ($simText -match "FAIL:") {
                Write-Host "FAIL: memory benchmark $($bench.Name) latency=$latency"
                $failed = $true
            } elseif ($simText -notmatch "MEMPERF:") {
                Write-Host "FAIL: memory benchmark $($bench.Name) latency=$latency did not emit MEMPERF line"
                $failed = $true
            } else {
                Write-Host "PASS: memory benchmark $($bench.Name) latency=$latency"
            }
        }
    }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd) { $python = $pythonCmd.Source }
    }
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        Write-Host "FAIL: python was not found, so memory latency summaries could not be generated"
        $failed = $true
    } else {
        & $python .\scripts\summarize_memory_latency_reports.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: memory latency summary generation failed"
            $failed = $true
        }
    }
} finally {
    Pop-Location
}

if ($failed) { exit 1 }

Write-Host "PASS: Phase 10 memory-latency flow completed"
Write-Host "Summary Markdown: reports\perf\memory_latency_summary.md"
Write-Host "Summary CSV: reports\perf\memory_latency_summary.csv"




