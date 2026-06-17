param(
    [switch]$SkipCompile
)
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$simDir = Join-Path $root "sim"
$perfDir = Join-Path $root "reports\perf"
$logDir = Join-Path $perfDir "benchmark_logs"
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
    "tb/tb_rv32i_pipeline_perf.sv"
)

$modes = @(
    @{ Name = "none"; Value = 0 },
    @{ Name = "simple"; Value = 1 },
    @{ Name = "gshare"; Value = 2 }
)

$benchmarks = @(
    @{ Name = "alu_chain"; Id = 0; Hex = "tests/benchmarks/alu_chain.hex"; EndPc = 196 },
    @{ Name = "mem_stream"; Id = 1; Hex = "tests/benchmarks/mem_stream.hex"; EndPc = 72 },
    @{ Name = "branch_loop"; Id = 2; Hex = "tests/benchmarks/branch_loop.hex"; EndPc = 88 },
    @{ Name = "mixed_program"; Id = 3; Hex = "tests/benchmarks/mixed_program.hex"; EndPc = 116 }
)

$failed = $false
Push-Location $root
try {
    foreach ($mode in $modes) {
        $out = Join-Path $simDir ("phase9_benchmark_{0}.vvp" -f $mode.Name)
        if (-not $SkipCompile) {
            iverilog -g2012 -Wall "-Ptb_rv32i_pipeline_perf.BP_MODE=$($mode.Value)" -o $out $rtl
        }

        foreach ($bench in $benchmarks) {
            $log = Join-Path $logDir ("{0}_{1}.log" -f $bench.Name, $mode.Name)
            Write-Host "== benchmark $($bench.Name) mode=$($mode.Name) =="
            $simOutput = vvp $out "+BENCH=$($bench.Name)" "+HEX=$($bench.Hex)" "+BENCH_ID=$($bench.Id)" "+END_PC=$($bench.EndPc)" 2>&1
            $simOutput | ForEach-Object { Write-Host $_ }
            $simOutput | Set-Content -LiteralPath $log -Encoding ASCII
            $simText = ($simOutput | Out-String)
            if ($simText -match "FAIL:") {
                Write-Host "FAIL: benchmark $($bench.Name) mode=$($mode.Name)"
                $failed = $true
            } elseif ($simText -notmatch "PERF:") {
                Write-Host "FAIL: benchmark $($bench.Name) mode=$($mode.Name) did not emit PERF line"
                $failed = $true
            } else {
                Write-Host "PASS: benchmark $($bench.Name) mode=$($mode.Name)"
            }
        }
    }

    $python = $env:PYTHON_EXECUTABLE
    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCmd) { $python = $pythonCmd.Source }
    }

    if (-not $python -or -not (Test-Path -LiteralPath $python)) {
        Write-Host "FAIL: python was not found, so benchmark summaries could not be generated"
        $failed = $true
    } else {
        & $python .\scripts\summarize_perf_reports.py
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: benchmark summary generation failed"
            $failed = $true
        }
    }
} finally {
    Pop-Location
}

if ($failed) { exit 1 }

Write-Host "PASS: Phase 9 benchmark flow completed"
Write-Host "Summary Markdown: reports\perf\benchmark_summary.md"
Write-Host "Summary CSV: reports\perf\benchmark_summary.csv"




