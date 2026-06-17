# Activates a nearby Windows OSS CAD Suite install for this PowerShell session.
# Expected layout for this project: E:\shixi02\tools\oss-cad-suite

$repoRoot = Split-Path -Parent $PSScriptRoot
$candidates = @(
    (Join-Path (Split-Path -Parent $repoRoot) "tools\oss-cad-suite"),
    "E:\shixi02\tools\oss-cad-suite"
)

$ossRoot = $null
foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath (Join-Path $candidate "bin\iverilog.exe")) {
        $ossRoot = $candidate
        break
    }
}

if (-not $ossRoot) {
    return
}

$env:YOSYSHQ_ROOT = $ossRoot
$env:SSL_CERT_FILE = Join-Path $ossRoot "etc\cacert.pem"
$env:PATH = "$ossRoot\bin;$ossRoot\lib;$env:PATH"
$env:PYTHON_EXECUTABLE = Join-Path $ossRoot "lib\python3.exe"
$env:QT_PLUGIN_PATH = Join-Path $ossRoot "lib\qt5\plugins"
$env:QT_LOGGING_RULES = "*=false"
$env:GTK_EXE_PREFIX = $ossRoot
$env:GTK_DATA_PREFIX = $ossRoot
$env:GDK_PIXBUF_MODULEDIR = Join-Path $ossRoot "lib\gdk-pixbuf-2.0\2.10.0\loaders"
$env:GDK_PIXBUF_MODULE_FILE = Join-Path $ossRoot "lib\gdk-pixbuf-2.0\2.10.0\loaders.cache"
$env:OPENFPGALOADER_SOJ_DIR = Join-Path $ossRoot "share\openFPGALoader"
$env:VERILATOR_ROOT = Join-Path $ossRoot "share\verilator"




