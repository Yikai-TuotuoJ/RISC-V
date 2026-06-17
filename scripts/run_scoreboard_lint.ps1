param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Log = Join-Path $Root "reports\lint_scoreboard.log"
New-Item -ItemType Directory -Force -Path (Join-Path $Root "reports") | Out-Null

Push-Location $Root
try {
    verilator_bin --lint-only -Wall `
        rtl\reservation_station_entry.sv `
        rtl\scoreboard_issue_model.sv 2>&1 | Tee-Object -FilePath $Log
} finally {
    Pop-Location
}
