param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Log = Join-Path $Root "reports\synth_ooo.log"
New-Item -ItemType Directory -Force -Path (Join-Path $Root "reports") | Out-Null
Push-Location $Root
try { yosys -s synth\synth_ooo.ys 2>&1 | Tee-Object -FilePath $Log } finally { Pop-Location }
