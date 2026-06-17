# Phase 0 Setup

This project is Windows-native. Do not use WSL or Ubuntu for the normal workflow.

## Recommended tools

Install OSS CAD Suite for Windows and add its `bin` directory to PATH. Install Git for Windows separately if needed.

Expected commands:

```powershell
Get-Command git
Get-Command python
Get-Command iverilog
Get-Command vvp
Get-Command verilator
Get-Command yosys
Get-Command gtkwave
```

Run:

```powershell
.\scripts\check_tools.ps1
```

If tools are missing, install/configure them before running simulation, lint, or synthesis.
