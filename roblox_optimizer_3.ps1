# Roblox Resource Farm Optimizer - Tray Version
# Optimized for idle farming using Windows-only resource limiting
# All settings toggleable from tray menu

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------
# Global settings
# ------------------------------
$global:OptCPU       = $true      # Enable CPU limiting
$global:OptGPU       = $true      # Enable GPU power saving
$global:OptCores     = 2          # 2, 4, or 0=All (2 minimum for stability)
$global:OptPriority  = 'BelowNormal'  # Idle / BelowNormal / Normal
$global:SilentMode   = $false

$cpuCount = [System.Environment]::ProcessorCount

function Get-AffinityMask {
    param(
        [int]$cores
    )
    # 0 or >= cpuCount => all cores
    if ($cores -le 0 -or $cores -ge $cpuCount) {
        return [int]([math]::Pow(2, $cpuCount) - 1)
    } else {
        return [int]([math]::Pow(2, $cores) - 1)
    }
}

# ------------------------------
# Windows Graphics Power Preference
# ------------------------------
function Set-GraphicsPowerPreference {
    param(
        [string]$exePath,
        [bool]$powerSaving
    )
    
    try {
        $regPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        
        # Create registry path if it doesn't exist
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        if ($powerSaving) {
            # Set to power saving mode (GpuPreference=1)
            Set-ItemProperty -Path $regPath -Name $exePath -Value "GpuPreference=1;" -Type String
        } else {
            # Remove preference (use system default)
            Remove-ItemProperty -Path $regPath -Name $exePath -ErrorAction SilentlyContinue
        }
        
        return $true
    } catch {
        return $false
    }
}

function Get-RobloxExecutablePath {
    $procs = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    if ($procs) {
        try {
            return $procs[0].Path
        } catch {
            return $null
        }
    }
    return $null
}

# ------------------------------
# Notification helper
# ------------------------------
function Show-Notification {
    param(
        [string]$title,
        [string]$text
    )

    if (-not $global:SilentMode -and $script:notifyIcon) {
        $script:notifyIcon.BalloonTipTitle = $title
        $script:notifyIcon.BalloonTipText  = $text
        $script:notifyIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
        $script:notifyIcon.ShowBalloonTip(3000)
    }
}

# ------------------------------
# Update tray tooltip with current status
# ------------------------------
function Update-TrayTooltip {
    $cpuStatus = if ($global:OptCPU) { "CPU: $global:OptCores cores, $global:OptPriority" } else { "CPU: OFF" }
    $gpuStatus = if ($global:OptGPU) { "GPU: Power Saving" } else { "GPU: OFF" }
    $script:notifyIcon.Text = "Roblox Optimizer`n$cpuStatus`n$gpuStatus"
}

# ------------------------------
# Hidden form as app context
# ------------------------------
$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar = $false
$form.WindowState   = 'Minimized'
$form.Opacity       = 0

# ------------------------------
# Tray icon setup
# ------------------------------
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon    = [System.Drawing.SystemIcons]::Application
$notifyIcon.Visible = $true
$script:notifyIcon  = $notifyIcon

# ------------------------------
# Context menu
# ------------------------------
$menu = New-Object System.Windows.Forms.ContextMenuStrip

# Enable CPU Optimization
$cpuOptItem = New-Object System.Windows.Forms.ToolStripMenuItem("Enable CPU Limiting")
$cpuOptItem.CheckOnClick = $true
$cpuOptItem.Checked = $global:OptCPU

$cpuOptItem.Add_Click({
    param($sender, $eventArgs)
    $global:OptCPU = $sender.Checked
    
    if (-not $global:OptCPU) {
        # Restore CPU settings to default
        $procs = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
        $priorityEnum = [System.Diagnostics.ProcessPriorityClass]::Normal
        $affinityMask = Get-AffinityMask 0

        foreach ($p in $procs) {
            try {
                $p.PriorityClass     = $priorityEnum
                $p.ProcessorAffinity = $affinityMask
            } catch {}
        }
        Show-Notification "Roblox Optimizer" "CPU limiting disabled."
    } else {
        Show-Notification "Roblox Optimizer" "CPU limiting enabled ($global:OptCores cores, $global:OptPriority)."
    }
    
    Update-TrayTooltip
})

# Enable GPU Optimization
$gpuOptItem = New-Object System.Windows.Forms.ToolStripMenuItem("Enable GPU Power Saving")
$gpuOptItem.CheckOnClick = $true
$gpuOptItem.Checked = $global:OptGPU

$gpuOptItem.Add_Click({
    param($sender, $eventArgs)
    $global:OptGPU = $sender.Checked
    
    $robloxPath = Get-RobloxExecutablePath
    if ($robloxPath) {
        $success = Set-GraphicsPowerPreference $robloxPath $global:OptGPU
        if ($success) {
            $mode = if ($global:OptGPU) { "enabled" } else { "disabled" }
            Show-Notification "Roblox Optimizer" "GPU power saving $mode. Restart Roblox for changes."
        } else {
            Show-Notification "Roblox Optimizer" "Failed to set GPU preference."
        }
    } else {
        if ($global:OptGPU) {
            Show-Notification "Roblox Optimizer" "GPU power saving will apply when Roblox starts."
        } else {
            Show-Notification "Roblox Optimizer" "GPU power saving disabled."
        }
    }
    
    Update-TrayTooltip
})

# Restore All Defaults
$restoreItem = New-Object System.Windows.Forms.ToolStripMenuItem("Restore All to Default")
$restoreItem.Add_Click({
    # Restore CPU
    $procs = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
    $priorityEnum = [System.Diagnostics.ProcessPriorityClass]::Normal
    $affinityMask = Get-AffinityMask 0

    foreach ($p in $procs) {
        try {
            $p.PriorityClass     = $priorityEnum
            $p.ProcessorAffinity = $affinityMask
        } catch {}
    }

    # Restore GPU
    $robloxPath = Get-RobloxExecutablePath
    if ($robloxPath) {
        Set-GraphicsPowerPreference $robloxPath $false
    }

    # Uncheck optimization toggles
    $cpuOptItem.Checked = $false
    $gpuOptItem.Checked = $false
    $global:OptCPU = $false
    $global:OptGPU = $false

    Show-Notification "Roblox Optimizer" "All optimizations disabled. Settings restored to default."
    Update-TrayTooltip
})

# Priority submenu
$priorityMenu = New-Object System.Windows.Forms.ToolStripMenuItem("CPU Priority")

$priorityItems = @(
    @{ Text = "Low (Idle)";    Tag = "Idle" },
    @{ Text = "Below Normal";  Tag = "BelowNormal" },
    @{ Text = "Normal";        Tag = "Normal" }
)

$script:prioritySubItems = @()

foreach ($pi in $priorityItems) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem($pi.Text)
    $item.Tag = $pi.Tag
    if ($pi.Tag -eq $global:OptPriority) {
        $item.Checked = $true
    }
    $item.Add_Click({
        param($sender, $eventArgs)
        # Uncheck others
        foreach ($other in $script:prioritySubItems) {
            $other.Checked = $false
        }
        $sender.Checked = $true
        $global:OptPriority = $sender.Tag
        Show-Notification "Roblox Optimizer" "CPU priority set to $($sender.Text)."
        Update-TrayTooltip
    })
    $priorityMenu.DropDownItems.Add($item) | Out-Null
    $script:prioritySubItems += $item
}

# Affinity submenu
$affinityMenu = New-Object System.Windows.Forms.ToolStripMenuItem("CPU Cores")

$affinityItems = @(
    @{ Text = "2 Cores (Recommended)"; Cores = 2 },
    @{ Text = "4 Cores"; Cores = 4 },
    @{ Text = "All Cores"; Cores = 0 }
)

$script:affinitySubItems = @()

foreach ($ai in $affinityItems) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem($ai.Text)
    $item.Tag = $ai.Cores
    if ($ai.Cores -eq $global:OptCores) {
        $item.Checked = $true
    }
    $item.Add_Click({
        param($sender, $eventArgs)
        foreach ($other in $script:affinitySubItems) {
            $other.Checked = $false
        }
        $sender.Checked = $true
        $global:OptCores = [int]$sender.Tag
        Show-Notification "Roblox Optimizer" "CPU cores set to $($sender.Text)."
        Update-TrayTooltip
    })
    $affinityMenu.DropDownItems.Add($item) | Out-Null
    $script:affinitySubItems += $item
}

# Silent Mode
$silentItem = New-Object System.Windows.Forms.ToolStripMenuItem("Silent Mode")
$silentItem.CheckOnClick = $true
$silentItem.Add_Click({
    param($sender, $eventArgs)
    $global:SilentMode = $sender.Checked
    if (-not $global:SilentMode) {
        Show-Notification "Roblox Optimizer" "Silent Mode disabled. Notifications enabled."
    }
})

# Exit
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$exitItem.Add_Click({
    $timer.Stop()
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    $form.Close()
    [System.Windows.Forms.Application]::Exit()
})

# Build menu
$menu.Items.Add($cpuOptItem) | Out-Null
$menu.Items.Add($gpuOptItem) | Out-Null
$menu.Items.Add($restoreItem)| Out-Null
$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
$menu.Items.Add($priorityMenu) | Out-Null
$menu.Items.Add($affinityMenu) | Out-Null
$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
$menu.Items.Add($silentItem) | Out-Null
$menu.Items.Add($exitItem) | Out-Null

$notifyIcon.ContextMenuStrip = $menu

# ------------------------------
# Optimization timer
# ------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000  # Check every 3 seconds

$timer.Add_Tick({
    # Apply CPU optimization if enabled
    if ($global:OptCPU) {
        $procs = Get-Process -Name "RobloxPlayerBeta" -ErrorAction SilentlyContinue
        if ($procs) {
            # Map priority string to enum
            try {
                $priorityEnum = [System.Diagnostics.ProcessPriorityClass]::$global:OptPriority
            } catch {
                $priorityEnum = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            }

            $affinityMask = Get-AffinityMask $global:OptCores

            foreach ($p in $procs) {
                try {
                    if ($p.PriorityClass -ne $priorityEnum) {
                        $p.PriorityClass = $priorityEnum
                    }
                    if ($p.ProcessorAffinity -ne $affinityMask) {
                        $p.ProcessorAffinity = $affinityMask
                    }
                } catch {
                    # Ignore processes that disappear mid-update
                }
            }
        }
    }
    
    # Apply GPU optimization if enabled and not already set
    if ($global:OptGPU) {
        $robloxPath = Get-RobloxExecutablePath
        if ($robloxPath) {
            # Check if GPU preference is already set
            $regPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
            if (Test-Path $regPath) {
                $currentValue = (Get-ItemProperty -Path $regPath -Name $robloxPath -ErrorAction SilentlyContinue).$robloxPath
                if ($currentValue -ne "GpuPreference=1;") {
                    Set-GraphicsPowerPreference $robloxPath $true
                }
            } else {
                Set-GraphicsPowerPreference $robloxPath $true
            }
        }
    }
})

$timer.Start()
Update-TrayTooltip

Show-Notification "Roblox Optimizer" "Optimizer started. Both CPU and GPU limiting enabled by default. Right-click icon to toggle settings."

# Run the message loop (keeps tray app alive)
[System.Windows.Forms.Application]::Run($form)