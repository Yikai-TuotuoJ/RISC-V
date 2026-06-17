param()
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$patterns = @(
    "sim\*.vvp",
    "sim\*.vcd",
    "reports\*.log",
    "reports\*.ys"
)
foreach ($pattern in $patterns) {
    Get-ChildItem -Path (Join-Path $root $pattern) -ErrorAction SilentlyContinue | Remove-Item -Force
}
Write-Host "Cleaned generated simulation and report files."



