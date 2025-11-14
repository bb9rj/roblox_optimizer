# Roblox Resource Farm Optimizer — Tray Version
A lightweight Windows tray application that reduces CPU, GPU, and power usage for running Roblox Player processes by adjusting process priority, CPU affinity, and graphics power preferences.

This tool operates purely at the OS level. It does not modify game files or interact with gameplay. It only controls how Windows allocates hardware resources to Roblox processes, enabling smoother multitasking and significantly reduced system load.

-----------------------------------------------------------------------

## Features

CPU Limiting
- Restricts each Roblox instance to a defined number of CPU cores (2, 4, or all).
- Uses Windows ProcessorAffinity to lower CPU overhead.
- Default: 2 cores (recommended).

GPU Power Saving
- Applies DirectX "GpuPreference=1" for low-power GPU mode.
- Reduces unnecessary GPU rendering.
- Requires Roblox restart to take effect.

Adjustable CPU Priority
- Idle
- BelowNormal (default)
- Normal

Tray Menu Controls
- CPU limiting toggle
- GPU power saving toggle
- CPU core selection
- Priority selection
- Silent mode toggle
- Restore defaults
- Exit

Automatic Application
- Settings refresh every 3 seconds.
- Newly opened Roblox windows are optimized automatically.

100% OS-Level Only
- Does not modify game files.
- Does not automate gameplay.
- Does not hook or inject into processes.
- Only adjusts Windows scheduling and power preferences.

-----------------------------------------------------------------------

## Why It Reduces CPU Load

By default, each Roblox instance spreads its workload across all CPU cores.
With many instances, this causes:
- Excessive context switching
- High CPU usage
- Significant heat and throttling
- Reduced system responsiveness

By limiting each instance to fewer cores and lowering priority:
- Windows schedules them more efficiently
- Background rendering no longer spikes CPU usage
- Overall CPU usage often drops from 80–100% down to 20–40%

Internal Roblox timers and logic are unaffected because only OS-level resource allocation is changed.

-----------------------------------------------------------------------

## Settings Overview

OptCPU  
Enable or disable CPU limiting:
   $global:OptCPU = $true

OptGPU  
Enable GPU power saving mode:
   $global:OptGPU = $true

OptCores  
Number of CPU cores Roblox may use:
- 2 cores (recommended)
- 4 cores
- 0 = all cores (no limit)
   $global:OptCores = 2

OptPriority  
Windows process priority:
   $global:OptPriority = 'BelowNormal'

SilentMode  
Disable or enable tray notifications:
   $global:SilentMode = $false

-----------------------------------------------------------------------

## Internal Operation

CPU Optimization
- Finds all RobloxPlayerBeta.exe processes.
- Applies selected priority class.
- Applies CPU affinity mask.
- Re-applies every 3 seconds automatically.

GPU Optimization
- Sets registry key:
  HKCU\Software\Microsoft\DirectX\UserGpuPreferences
- Applies "GpuPreference=1;" for power saving.

Tray Application
- Uses a hidden Windows Forms application.
- Displays a tray icon with live status.
- Provides a full right-click configuration menu.

-----------------------------------------------------------------------

## Installation

1. Save the script

2. You can run it by right-clicking:
   Run with PowerShell

3. If your system has script execution restrictions, you may need to run:
   powershell -ExecutionPolicy Bypass -File "C:\Path\To\Script_Name.ps1"

   Example:
   powershell -ExecutionPolicy Bypass -File "C:\Users\Computer\Documents\Roblox\Helpers\Script_Name.ps1"

4. A tray icon will appear.
   Right-click it to access settings.

-----------------------------------------------------------------------

## Restoring Defaults

Choose:
   Restore All to Default

This resets:
- CPU priority to Normal
- Affinity mask to all cores
- Removes GPU power settings
- Turns off all optimizations

-----------------------------------------------------------------------

## Disclaimer

This script performs only OS-level CPU/GPU scheduling adjustments.  
It does not automate, modify, or interact with Roblox gameplay or data.  
Use responsibly.

-----------------------------------------------------------------------

## License

MIT License
