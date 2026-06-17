param()
. $PSScriptRoot\setup_oss_cad_env.ps1
$ErrorActionPreference = "SilentlyContinue"

$tools = @("iverilog", "vvp", "verilator_bin", "yosys", "gtkwave")
$optionalTools = @("git")
$missing = @()
$missingOptional = @()
$broken = @()

Write-Host "Checking Windows-native RTL toolchain..."
foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[FOUND]   {0} -> {1}" -f $tool, $cmd.Source)
    } else {
        Write-Host ("[MISSING] {0}" -f $tool)
        $missing += $tool
    }
}
foreach ($tool in $optionalTools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[FOUND]   {0} -> {1}" -f $tool, $cmd.Source)
    } else {
        Write-Host ("[OPTIONAL MISSING] {0}" -f $tool)
        $missingOptional += $tool
    }
}

Write-Host ""
Write-Host "Version checks for available tools:"
$versionCommands = @(
    @{Name="iverilog"; Args=@("-V")},
    @{Name="vvp"; Args=@("-V")},
    @{Name="verilator_bin"; Args=@("--version")},
    @{Name="yosys"; Args=@("-V")},
    @{Name="gtkwave"; Args=@("--version")},
    @{Name="git"; Args=@("--version")}
)

foreach ($entry in $versionCommands) {
    if (Get-Command $entry.Name -ErrorAction SilentlyContinue) {
        Write-Host "--- $($entry.Name) ---"
        try {
            $output = & $entry.Name @($entry.Args) 2>&1
            $exit = $LASTEXITCODE
            $output | Select-Object -First 5
            if ($exit -ne 0) {
                Write-Host ("[BROKEN] {0} returned exit code {1}" -f $entry.Name, $exit)
                $broken += $entry.Name
            }
        } catch {
            Write-Host ("[BROKEN] {0}: {1}" -f $entry.Name, $_.Exception.Message)
            $broken += $entry.Name
        }
    }
}

if (($missing.Count -gt 0) -or ($broken.Count -gt 0)) {
    Write-Host ""
    if ($missing.Count -gt 0) { Write-Host "Missing required tools: $($missing -join ', ')" }
    if ($broken.Count -gt 0) { Write-Host "Broken tools: $($broken -join ', ')" }
    Write-Host "Recommended: install OSS CAD Suite for Windows under E:\shixi02\tools\oss-cad-suite."
    exit 1
}

Write-Host ""
Write-Host "All required Phase 1 RTL tools were found and responded to version checks."
if ($missingOptional.Count -gt 0) {
    Write-Host "Optional tools not found: $($missingOptional -join ', ')"
}




