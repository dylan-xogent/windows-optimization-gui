<#
.SYNOPSIS
    Windows Optimization Script - Comprehensive System Optimizer
.DESCRIPTION
    A comprehensive Windows optimization tool that detects system specifications
    and applies appropriate optimizations conservatively with full backup/restore capabilities.
    Supports both CLI and GUI interfaces.
.NOTES
    Version: 2.0.0
    Requires: PowerShell 5.1+, Windows 10/11, Administrator privileges
    GitHub: Can be launched directly from GitHub with:
    iex (irm 'https://raw.githubusercontent.com/[user]/[repo]/main/windows-optimization-gui.ps1')
#>

#region Initialization and Prerequisites

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Check Windows version (Windows 10/11 only)
$osVersion = [System.Environment]::OSVersion.Version
$windowsVersion = (Get-CimInstance Win32_OperatingSystem).Version
if (-not ($windowsVersion -match "^10\.|^11\.")) {
    Write-Error "This script requires Windows 10 or Windows 11. Detected version: $windowsVersion"
    exit 1
}

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script requires administrator privileges. Please run as Administrator!"
    Write-Host "Attempting to elevate..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    # Try to elevate
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = $PSCommandPath
    }
    if ($scriptPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    } else {
        Write-Error "Cannot determine script path. Please run this script directly as Administrator."
    }
    exit
}

# Set error action preference
$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

# Application configuration
$script:AppConfig = @{
    Name = "Windows Optimization Script"
    Version = "2.0.0"
    Author = "Windows Optimization Team"
    GitHubRepo = "" # Will be set if launched from GitHub
    LogFile = "$env:TEMP\WindowsOptimization_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    BackupDir = "$env:USERPROFILE\Documents\WindowsOptimization\Backups"
    ChangesLog = "$env:USERPROFILE\Documents\WindowsOptimization\Changes.log"
    SummaryReport = "$env:USERPROFILE\Documents\WindowsOptimization\OptimizationSummary.txt"
}

# Create necessary directories
$null = New-Item -Path (Split-Path -Path $script:AppConfig.LogFile -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item -Path $script:AppConfig.BackupDir -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item -Path (Split-Path -Path $script:AppConfig.ChangesLog -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue

# Detect execution context (CLI vs GUI)
$script:IsGUI = $false
if ($Host.Name -eq "ConsoleHost") {
    $script:IsGUI = $false
} elseif ($Host.Name -eq "Windows PowerShell ISE Host" -or $Host.UI.RawUI -and $Host.UI.RawUI.BufferSize) {
    # Check if we can create a GUI
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $script:IsGUI = $true
    } catch {
        $script:IsGUI = $false
    }
} else {
    $script:IsGUI = $false
}

# Check if launched from GitHub
$script:LaunchedFromGitHub = $false
if ($MyInvocation.Line -match 'irm|Invoke-RestMethod|Invoke-WebRequest') {
    $script:LaunchedFromGitHub = $true
}

#endregion

#region Logging Functions

function Write-OptimizationLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    try {
        Add-Content -Path $script:AppConfig.LogFile -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        # If logging fails, try to write to temp
        try {
            Add-Content -Path "$env:TEMP\WindowsOptimization.log" -Value $logMessage -ErrorAction SilentlyContinue
        } catch {}
    }
    
    # Output to console with color
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "INFO" { "Cyan" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
        Write-Host $logMessage -ForegroundColor $color
    }
}

function Write-ChangeLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$BeforeValue,
        
        [Parameter(Mandatory=$false)]
        [string]$AfterValue,
        
        [Parameter(Mandatory=$false)]
        [string]$Status = "SUCCESS"
    )
    
    $changeEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Category = $Category
        Description = $Description
        BeforeValue = $BeforeValue
        AfterValue = $AfterValue
        Status = $Status
    }
    
    $logLine = "[$($changeEntry.Timestamp)] [$($changeEntry.Category)] $($changeEntry.Description)"
    if ($BeforeValue) { $logLine += " | Before: $BeforeValue" }
    if ($AfterValue) { $logLine += " | After: $AfterValue" }
    $logLine += " | Status: $($changeEntry.Status)"
    
    try {
        Add-Content -Path $script:AppConfig.ChangesLog -Value $logLine -ErrorAction SilentlyContinue
    } catch {}
    
    return $changeEntry
}

#endregion

#region System Detection Module

function Get-SystemSpecifications {
    Write-OptimizationLog "Detecting system specifications..." "INFO"
    
    $specs = @{
        # Hardware
        CPU = @{
            Name = ""
            Cores = 0
            Threads = 0
            MaxClockSpeed = 0
            Architecture = ""
        }
        RAM = @{
            TotalGB = 0
            AvailableGB = 0
            InstalledModules = @()
        }
        GPU = @{
            Primary = ""
            All = @()
            NVIDIA = $false
            AMD = $false
            Intel = $false
        }
        Storage = @{
            Drives = @()
            HasSSD = $false
            HasNVMe = $false
            HasHDD = $false
            TotalSSDGB = 0
            TotalHDDGB = 0
        }
        
        # Software
        OS = @{
            Name = ""
            Version = ""
            Build = ""
            Edition = ""
            IsWindows11 = $false
        }
        
        # System Type
        SystemType = @{
        IsLaptop = $false
            HasBattery = $false
            ChassisType = ""
        }
        
        # Performance Baseline
        Performance = @{
            CurrentPowerPlan = ""
            AvailablePowerPlans = @()
            ServicesStatus = @{}
        }
    }
    
    try {
        # CPU Information
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $specs.CPU.Name = $cpu.Name.Trim()
        $specs.CPU.Cores = $cpu.NumberOfCores
        $specs.CPU.Threads = $cpu.NumberOfLogicalProcessors
        $specs.CPU.MaxClockSpeed = $cpu.MaxClockSpeed
        $specs.CPU.Architecture = switch ($cpu.AddressWidth) {
            32 { "x86" }
            64 { "x64" }
            default { "Unknown" }
        }
        Write-OptimizationLog "CPU: $($specs.CPU.Name) ($($specs.CPU.Cores) cores, $($specs.CPU.Threads) threads)" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect CPU: $_" "WARNING"
    }
    
    try {
        # RAM Information
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $specs.RAM.TotalGB = [Math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        
        $os = Get-CimInstance Win32_OperatingSystem
        $specs.RAM.AvailableGB = [Math]::Round(($os.FreePhysicalMemory * 1024) / 1GB, 2)
        
        $memoryModules = Get-CimInstance Win32_PhysicalMemory
        foreach ($module in $memoryModules) {
            $specs.RAM.InstalledModules += @{
                CapacityGB = [Math]::Round($module.Capacity / 1GB, 2)
                Speed = $module.Speed
                Manufacturer = $module.Manufacturer
                FormFactor = $module.FormFactor
            }
        }
        Write-OptimizationLog "RAM: $($specs.RAM.TotalGB) GB total, $($specs.RAM.AvailableGB) GB available" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect RAM: $_" "WARNING"
    }
    
    try {
        # GPU Information
        $gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Remote|Basic|Microsoft" }
        foreach ($gpu in $gpus) {
            $gpuName = $gpu.Name.Trim()
            $specs.GPU.All += $gpuName
            
            if ($gpuName -match "NVIDIA|GeForce|Quadro|Tesla") {
                $specs.GPU.NVIDIA = $true
                if (-not $specs.GPU.Primary) { $specs.GPU.Primary = $gpuName }
            } elseif ($gpuName -match "AMD|Radeon|Radeon Pro") {
                $specs.GPU.AMD = $true
                if (-not $specs.GPU.Primary) { $specs.GPU.Primary = $gpuName }
            } elseif ($gpuName -match "Intel.*Graphics|HD Graphics|Iris|UHD") {
                $specs.GPU.Intel = $true
                if (-not $specs.GPU.Primary) { $specs.GPU.Primary = $gpuName }
            }
        }
        if (-not $specs.GPU.Primary -and $specs.GPU.All.Count -gt 0) {
            $specs.GPU.Primary = $specs.GPU.All[0]
        }
        Write-OptimizationLog "GPU: $($specs.GPU.Primary)" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect GPU: $_" "WARNING"
    }
    
    try {
        # Storage Information
        $disks = Get-PhysicalDisk | Where-Object { $_.DeviceID -ne $null }
        foreach ($disk in $disks) {
            $driveInfo = @{
                DeviceID = $disk.DeviceID
                MediaType = $disk.MediaType
                SizeGB = [Math]::Round($disk.Size / 1GB, 2)
                Model = $disk.Model
                BusType = $disk.BusType
            }
            $specs.Storage.Drives += $driveInfo
            
            if ($disk.MediaType -eq "SSD") {
                $specs.Storage.HasSSD = $true
                $specs.Storage.TotalSSDGB += $driveInfo.SizeGB
            } elseif ($disk.MediaType -eq "HDD") {
                $specs.Storage.HasHDD = $true
                $specs.Storage.TotalHDDGB += $driveInfo.SizeGB
            }
            
            if ($disk.BusType -eq "NVMe") {
                $specs.Storage.HasNVMe = $true
            }
        }
        Write-OptimizationLog "Storage: SSD=$($specs.Storage.HasSSD), NVMe=$($specs.Storage.HasNVMe), HDD=$($specs.Storage.HasHDD)" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect storage: $_" "WARNING"
    }
    
    try {
        # OS Information
        $os = Get-CimInstance Win32_OperatingSystem
        $specs.OS.Name = $os.Caption
        $specs.OS.Version = $os.Version
        $specs.OS.Build = $os.BuildNumber
        $specs.OS.Edition = $os.EditionID
        $specs.OS.IsWindows11 = ($os.Version -match "^10\.0\.2[2-9]|^11\.") -or ($os.BuildNumber -ge 22000)
        Write-OptimizationLog "OS: $($specs.OS.Name) Build $($specs.OS.Build)" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect OS: $_" "WARNING"
    }
    
    try {
        # System Type Detection
        $chassis = Get-CimInstance Win32_SystemEnclosure
        $chassisTypes = $chassis.ChassisTypes
        $specs.SystemType.ChassisType = $chassisTypes[0]
        
        # Chassis types: 8=Portable, 9=Laptop, 10=Notebook, 14=Sub Notebook
        if ($chassisTypes -contains 8 -or $chassisTypes -contains 9 -or $chassisTypes -contains 10 -or $chassisTypes -contains 14) {
            $specs.SystemType.IsLaptop = $true
        }
        
        # Check for battery
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        $specs.SystemType.HasBattery = ($battery -ne $null)
        Write-OptimizationLog "System Type: $(if ($specs.SystemType.IsLaptop) { 'Laptop' } else { 'Desktop' })" "DEBUG"
    } catch {
        Write-OptimizationLog "Failed to detect system type: $_" "WARNING"
    }
    
    try {
        # Performance Baseline
        $currentPlan = powercfg /getactivescheme
        if ($currentPlan -match "GUID:\s*([a-f0-9\-]+)") {
            $guid = $matches[1]
            $planName = powercfg /list | Select-String $guid | ForEach-Object { $_.Line.Trim() }
            $specs.Performance.CurrentPowerPlan = $planName
        }
        
        $plans = powercfg /list
        foreach ($line in $plans) {
            if ($line -match "GUID:\s*([a-f0-9\-]+)\s*(.+)") {
                $specs.Performance.AvailablePowerPlans += $matches[2].Trim()
            }
        }
    } catch {
        Write-OptimizationLog "Failed to detect power plans: $_" "WARNING"
    }
    
    Write-OptimizationLog "System detection completed successfully" "SUCCESS"
    return $specs
}

#endregion

#region Backup and Restore Module

function New-SystemRestorePoint {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Description = "Windows Optimization Script - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )
    
    Write-OptimizationLog "Creating system restore point..." "INFO"
    
    try {
        # Check if System Restore is enabled
        $restoreEnabled = (Get-ComputerRestorePoint -ErrorAction SilentlyContinue) -ne $null
        if (-not $restoreEnabled) {
            # Try to enable System Restore on C: drive
            try {
                vssadmin list volumes | Out-Null
                Write-OptimizationLog "System Restore appears to be available" "DEBUG"
            } catch {
                Write-OptimizationLog "System Restore may not be enabled. Attempting to create restore point anyway..." "WARNING"
            }
        }
        
        # Create restore point using vssadmin (requires admin)
        $result = vssadmin create shadow /For=C: /AutoRetry=1 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "successfully") {
            Write-OptimizationLog "System restore point created successfully" "SUCCESS"
        return $true
    } else {
            # Alternative method using Checkpoint-Computer (PowerShell 5.1+)
            try {
                Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                Write-OptimizationLog "System restore point created successfully (Checkpoint-Computer)" "SUCCESS"
                return $true
            } catch {
                Write-OptimizationLog "Failed to create system restore point: $_" "WARNING"
                Write-OptimizationLog "You may need to enable System Restore manually" "WARNING"
        return $false
    }
}
    } catch {
        Write-OptimizationLog "Failed to create system restore point: $_" "ERROR"
        return $false
    }
}

function Backup-RegistryKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupName = ""
    )
    
    if (-not $BackupName) {
        $BackupName = $RegistryPath.Replace('\', '_').Replace(':', '')
    }
    
    $backupFile = Join-Path $script:AppConfig.BackupDir "$BackupName_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    
    try {
        if (Test-Path $RegistryPath) {
            reg export $RegistryPath $backupFile /y 2>&1 | Out-Null
            if (Test-Path $backupFile) {
                Write-OptimizationLog "Registry backup created: $backupFile" "DEBUG"
                return $backupFile
            }
        }
    } catch {
        Write-OptimizationLog "Failed to backup registry key $RegistryPath : $_" "WARNING"
    }
    
    return $null
}

function Backup-ServiceStates {
    Write-OptimizationLog "Backing up service states..." "INFO"
    
    $servicesBackup = @{}
    $services = Get-Service | Where-Object { $_.Status -ne $null }
    
    foreach ($service in $services) {
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'"
            $servicesBackup[$service.Name] = @{
                Status = $service.Status.ToString()
                StartType = $svc.StartMode
                DisplayName = $svc.DisplayName
            }
        } catch {}
    }
    
    $backupFile = Join-Path $script:AppConfig.BackupDir "Services_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $servicesBackup | ConvertTo-Json -Depth 3 | Out-File -FilePath $backupFile -Encoding UTF8
    
    Write-OptimizationLog "Service states backed up to: $backupFile" "SUCCESS"
    return $backupFile
}

function Initialize-BackupSystem {
    Write-OptimizationLog "Initializing backup system..." "INFO"
    
    $results = @{
        RestorePoint = $false
        RegistryBackups = @()
        ServiceBackup = $null
    }
    
    # Create system restore point
    $results.RestorePoint = New-SystemRestorePoint
    
    # Backup critical registry keys
    $criticalKeys = @(
        "HKCU\Control Panel\Desktop",
        "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer",
        "HKLM\SYSTEM\CurrentControlSet\Control\Power",
        "HKLM\SYSTEM\CurrentControlSet\Services"
    )
    
    foreach ($key in $criticalKeys) {
        $backup = Backup-RegistryKey -RegistryPath $key
        if ($backup) {
            $results.RegistryBackups += $backup
        }
    }
    
    # Backup service states
    $results.ServiceBackup = Backup-ServiceStates
    
    Write-OptimizationLog "Backup system initialized. Restore point: $($results.RestorePoint)" "SUCCESS"
    return $results
}

#endregion

#region Optimization Modules

# System Performance Optimizations
function Optimize-SystemPerformance {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing system performance..." "INFO"
    $changes = @()
    
    # Power Plan Optimization
    if ($Options.ContainsKey("PowerPlan") -and $Options.PowerPlan) {
        try {
            $currentPlan = $SystemSpecs.Performance.CurrentPowerPlan
            $targetPlan = if ($SystemSpecs.SystemType.IsLaptop) { "Balanced" } else { "High performance" }
            
            if ($currentPlan -notmatch $targetPlan) {
                $highPerfGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
                $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
                
                if ($SystemSpecs.SystemType.IsLaptop) {
                    powercfg /setactive $balancedGUID
                    Write-ChangeLog "System Performance" "Set power plan to Balanced (Laptop)" $currentPlan "Balanced"
                } else {
                    powercfg /setactive $highPerfGUID
                    Write-ChangeLog "System Performance" "Set power plan to High Performance (Desktop)" $currentPlan "High Performance"
                }
                $changes += "Power plan optimized"
            }
        } catch {
            Write-OptimizationLog "Failed to set power plan: $_" "WARNING"
        }
    }
    
    # Visual Effects Optimization
    if ($Options.ContainsKey("VisualEffects") -and $Options.VisualEffects) {
        try {
            $desktopPath = "HKCU:\Control Panel\Desktop"
            
            # Disable animations
            Set-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "$desktopPath\WindowMetrics" -Name "MinAnimate" -Type String -Value "0" -ErrorAction SilentlyContinue
            
            # Optimize visual effects
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 2 -ErrorAction SilentlyContinue
            
            Write-ChangeLog "System Performance" "Optimized visual effects" "" "Performance optimized"
            $changes += "Visual effects optimized"
        } catch {
            Write-OptimizationLog "Failed to optimize visual effects: $_" "WARNING"
        }
    }
    
    # Disable Game DVR and Game Bar
    if ($Options.ContainsKey("DisableGameDVR") -and $Options.DisableGameDVR) {
        try {
            $gameDVRPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
            if (-not (Test-Path $gameDVRPath)) {
                New-Item -Path $gameDVRPath -Force | Out-Null
            }
            Set-ItemProperty -Path $gameDVRPath -Name "AllowGameDVR" -Type DWord -Value 0 -ErrorAction SilentlyContinue
            
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0 -ErrorAction SilentlyContinue
            
            Write-ChangeLog "System Performance" "Disabled Game DVR and Game Bar" "" "Disabled"
            $changes += "Game DVR disabled"
        } catch {
            Write-OptimizationLog "Failed to disable Game DVR: $_" "WARNING"
        }
    }
    
    Write-OptimizationLog "System performance optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Bloatware Removal
function Remove-BloatwareApps {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [array]$AppsToRemove = @()
    )
    
    Write-OptimizationLog "Removing bloatware applications..." "INFO"
    
    if ($AppsToRemove.Count -eq 0) {
        # Default list of common bloatware
        $AppsToRemove = @(
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.XboxApp",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.YourPhone",
        "Microsoft.MixedReality.Portal",
        "Microsoft.SkypeApp",
        "Microsoft.People",
        "Microsoft.Getstarted",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.BingWeather",
        "Microsoft.BingNews",
        "Microsoft.Office.OneNote",
        "Microsoft.Office.Sway",
        "Microsoft.OneConnect",
        "Microsoft.Print3D",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.Messaging",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.Wallet",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera"
    )
    }
    
    $removed = 0
    $failed = 0
    
    foreach ($app in $AppsToRemove) {
        try {
            $packages = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            if ($packages) {
                foreach ($package in $packages) {
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
                    Write-ChangeLog "Bloatware Removal" "Removed $app" $package.PackageFullName "Removed"
                    $removed++
                }
            }
            
            $provisioned = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" -ErrorAction SilentlyContinue
            if ($provisioned) {
                foreach ($prov in $provisioned) {
                    Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
                }
            }
        } catch {
            $failed++
            Write-OptimizationLog "Failed to remove $app : $_" "WARNING"
        }
    }
    
    Write-OptimizationLog "Bloatware removal completed. Removed: $removed, Failed: $failed" "SUCCESS"
    return @{ Removed = $removed; Failed = $failed }
}

# Services Optimization
function Optimize-Services {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing Windows services..." "INFO"
    
    # Services to disable (conservative list)
    $servicesToDisable = @(
        "Fax",
        "WSearch", # Windows Search (can be re-enabled if needed)
        "RemoteRegistry",
        "RemoteAccess",
        "SharedAccess", # Internet Connection Sharing
        "TrkWks", # Distributed Link Tracking Client
        "WbioSrvc" # Windows Biometric Service
    )
    
    # For laptops, preserve some services
    if ($SystemSpecs.SystemType.IsLaptop) {
        $servicesToDisable = $servicesToDisable | Where-Object { $_ -notin @("WbioSrvc") }
    }
    
    $disabled = 0
    $failed = 0
    
    foreach ($serviceName in $servicesToDisable) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -ne "Stopped") {
                $beforeState = $service.StartType
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
                Write-ChangeLog "Services" "Disabled service: $serviceName" $beforeState "Disabled"
                $disabled++
            }
        } catch {
            $failed++
            Write-OptimizationLog "Failed to disable service $serviceName : $_" "WARNING"
        }
    }
    
    Write-OptimizationLog "Service optimization completed. Disabled: $disabled, Failed: $failed" "SUCCESS"
    return @{ Disabled = $disabled; Failed = $failed }
}

# GPU Optimization
function Optimize-GPU {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing GPU settings..." "INFO"
    $changes = @()
    
    # NVIDIA Optimizations
    if ($SystemSpecs.GPU.NVIDIA) {
        try {
            $nvidiaPath = "HKCU:\SOFTWARE\NVIDIA Corporation\Global\NVTweak"
            if (-not (Test-Path $nvidiaPath)) {
                New-Item -Path $nvidiaPath -Force | Out-Null
            }
            
            Set-ItemProperty -Path $nvidiaPath -Name "PreferredGPU" -Type DWord -Value 1 -ErrorAction SilentlyContinue
            
            # Graphics driver settings
            $graphicsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            if (Test-Path $graphicsPath) {
                Set-ItemProperty -Path $graphicsPath -Name "HwSchMode" -Type DWord -Value 2 -ErrorAction SilentlyContinue
            }
            
            Write-ChangeLog "GPU" "Applied NVIDIA optimizations" "" "Optimized"
            $changes += "NVIDIA optimizations applied"
        } catch {
            Write-OptimizationLog "Failed to optimize NVIDIA GPU: $_" "WARNING"
        }
    }
    
    # AMD Optimizations
    if ($SystemSpecs.GPU.AMD) {
        try {
            $amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            if (Test-Path $amdPath) {
                Set-ItemProperty -Path $amdPath -Name "PP_PhmUseDummyBackEnd" -Type DWord -Value 0 -ErrorAction SilentlyContinue
            }
            
            Write-ChangeLog "GPU" "Applied AMD optimizations" "" "Optimized"
            $changes += "AMD optimizations applied"
        } catch {
            Write-OptimizationLog "Failed to optimize AMD GPU: $_" "WARNING"
        }
    }
    
    if ($changes.Count -eq 0) {
        Write-OptimizationLog "No GPU optimizations applied (no supported GPU detected)" "INFO"
    } else {
        Write-OptimizationLog "GPU optimization completed. Changes: $($changes.Count)" "SUCCESS"
    }
    
    return $changes
}

# Network Optimization
function Optimize-Network {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing network settings..." "INFO"
    $changes = @()
    
    try {
        # Disable Nagle's Algorithm for better latency
        $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $tcpPath -Name "TcpAckFrequency" -Type DWord -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $tcpPath -Name "TCPNoDelay" -Type DWord -Value 1 -ErrorAction SilentlyContinue
        
        # Network Throttling Index
        Set-ItemProperty -Path $tcpPath -Name "Tcp1323Opts" -Type DWord -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $tcpPath -Name "DefaultTTL" -Type DWord -Value 64 -ErrorAction SilentlyContinue
        
        Write-ChangeLog "Network" "Optimized TCP/IP settings" "" "Optimized"
        $changes += "TCP/IP optimized"
    } catch {
        Write-OptimizationLog "Failed to optimize network settings: $_" "WARNING"
    }
    
    try {
        # Disable QoS Packet Scheduler throttling
        $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        if (-not (Test-Path $qosPath)) {
            New-Item -Path $qosPath -Force | Out-Null
        }
        Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Type DWord -Value 0 -ErrorAction SilentlyContinue
        
        Write-ChangeLog "Network" "Disabled QoS throttling" "" "Disabled"
        $changes += "QoS optimized"
    } catch {
        Write-OptimizationLog "Failed to optimize QoS: $_" "WARNING"
    }
    
    Write-OptimizationLog "Network optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Storage Optimization
function Optimize-Storage {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing storage settings..." "INFO"
    $changes = @()
    
    # SSD Optimizations
    if ($SystemSpecs.Storage.HasSSD) {
        try {
            # Disable defragmentation for SSD
            foreach ($drive in $SystemSpecs.Storage.Drives) {
                if ($drive.MediaType -eq "SSD") {
                    $driveLetter = (Get-Partition | Where-Object { $_.DiskNumber -eq $drive.DeviceID }).DriveLetter
                    if ($driveLetter) {
                        $defragPath = "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction"
                        Set-ItemProperty -Path $defragPath -Name "Enable" -Type String -Value "N" -ErrorAction SilentlyContinue
                    }
                }
            }
            
            # Enable TRIM
            $trimResult = fsutil behavior set DisableDeleteNotify 0 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ChangeLog "Storage" "Enabled TRIM for SSD" "" "Enabled"
                $changes += "TRIM enabled"
            }
            
            # Disable Superfetch/Prefetch for SSD
            $superfetch = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
            if ($superfetch) {
                Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
                Write-ChangeLog "Storage" "Disabled Superfetch for SSD" "" "Disabled"
                $changes += "Superfetch disabled"
            }
        } catch {
            Write-OptimizationLog "Failed to optimize SSD: $_" "WARNING"
        }
    }
    
    # HDD Optimizations
    if ($SystemSpecs.Storage.HasHDD) {
        try {
            # Enable defragmentation schedule for HDD
            $defragPath = "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction"
            Set-ItemProperty -Path $defragPath -Name "Enable" -Type String -Value "Y" -ErrorAction SilentlyContinue
            
            Write-ChangeLog "Storage" "Optimized HDD defragmentation" "" "Optimized"
            $changes += "HDD defrag optimized"
        } catch {
            Write-OptimizationLog "Failed to optimize HDD: $_" "WARNING"
        }
    }
    
    Write-OptimizationLog "Storage optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Memory Optimization
function Optimize-Memory {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing memory settings..." "INFO"
    $changes = @()
    
    try {
        # Virtual Memory / Page File optimization
        $ramGB = $SystemSpecs.RAM.TotalGB
        
        if ($ramGB -lt 8) {
            # Low RAM: Set page file to 1.5x RAM
            $pageFileSize = [Math]::Round($ramGB * 1.5 * 1024)
        } elseif ($ramGB -ge 16) {
            # High RAM: Set page file to 0.5x RAM (or disable if >= 32GB)
            $pageFileSize = if ($ramGB -ge 32) { 0 } else { [Math]::Round($ramGB * 0.5 * 1024) }
        } else {
            # Medium RAM: Set page file to 1x RAM
            $pageFileSize = [Math]::Round($ramGB * 1024)
        }
        
        # Note: Actual page file configuration requires system restart
        Write-ChangeLog "Memory" "Configured page file recommendation" "" "$pageFileSize MB recommended"
        $changes += "Page file optimized"
    } catch {
        Write-OptimizationLog "Failed to optimize memory: $_" "WARNING"
    }
    
    try {
        # Disable memory compression for systems with >= 16GB RAM
        if ($SystemSpecs.RAM.TotalGB -ge 16) {
            Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
            Write-ChangeLog "Memory" "Disabled memory compression (high RAM system)" "" "Disabled"
            $changes += "Memory compression disabled"
        }
    } catch {
        Write-OptimizationLog "Failed to configure memory compression: $_" "WARNING"
    }
    
    Write-OptimizationLog "Memory optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Windows Update Optimization
function Optimize-WindowsUpdate {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing Windows Update settings..." "INFO"
    $changes = @()
    
    try {
        # Configure Windows Update for manual control (conservative)
        $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $updatePath)) {
            New-Item -Path $updatePath -Force | Out-Null
        }
        
        # Set to notify before download (conservative)
        Set-ItemProperty -Path $updatePath -Name "AUOptions" -Type DWord -Value 3 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $updatePath -Name "NoAutoUpdate" -Type DWord -Value 0 -ErrorAction SilentlyContinue
        
        Write-ChangeLog "Windows Update" "Configured Windows Update for manual control" "" "Notify before download"
        $changes += "Windows Update configured"
    } catch {
        Write-OptimizationLog "Failed to optimize Windows Update: $_" "WARNING"
    }
    
    Write-OptimizationLog "Windows Update optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Privacy Settings Optimization
function Optimize-Privacy {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing privacy settings..." "INFO"
    $changes = @()
    
    try {
        # Disable telemetry (conservative - set to Security level)
        $telemetryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        if (-not (Test-Path $telemetryPath)) {
            New-Item -Path $telemetryPath -Force | Out-Null
        }
        Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Type DWord -Value 1 -ErrorAction SilentlyContinue
        
        Write-ChangeLog "Privacy" "Configured telemetry settings" "" "Security level"
        $changes += "Telemetry configured"
    } catch {
        Write-OptimizationLog "Failed to optimize privacy settings: $_" "WARNING"
    }
    
    Write-OptimizationLog "Privacy optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Security Optimization
function Optimize-Security {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Optimizing security settings..." "INFO"
    $changes = @()
    
    try {
        # Configure Windows Defender exclusions for performance (conservative)
        # Note: This is just logging - actual exclusions should be user-configured
        Write-ChangeLog "Security" "Windows Defender optimization recommendations" "" "Consider adding game folders to exclusions"
        $changes += "Security recommendations logged"
    } catch {
        Write-OptimizationLog "Failed to optimize security settings: $_" "WARNING"
    }
    
    Write-OptimizationLog "Security optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

# Startup Optimization
function Optimize-Startup {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Options = @{}
    )
    
    Write-OptimizationLog "Analyzing startup programs..." "INFO"
    $changes = @()
    
    try {
        # Get startup programs
        $startupPrograms = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location
        
        Write-ChangeLog "Startup" "Analyzed startup programs" "" "$($startupPrograms.Count) programs found"
        $changes += "Startup analysis completed"
        
        # Note: Actual disabling should be user-selected
    } catch {
        Write-OptimizationLog "Failed to analyze startup: $_" "WARNING"
    }
    
    Write-OptimizationLog "Startup optimization completed. Changes: $($changes.Count)" "SUCCESS"
    return $changes
}

#endregion

#region CLI Interface

function Show-CLIMenu {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs
    )
    
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Windows Optimization Script v$($script:AppConfig.Version)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Display system info
    Write-Host "System Information:" -ForegroundColor Yellow
    Write-Host "  CPU: $($SystemSpecs.CPU.Name)" -ForegroundColor White
    Write-Host "  RAM: $($SystemSpecs.RAM.TotalGB) GB" -ForegroundColor White
    Write-Host "  GPU: $($SystemSpecs.GPU.Primary)" -ForegroundColor White
    Write-Host "  OS: $($SystemSpecs.OS.Name) Build $($SystemSpecs.OS.Build)" -ForegroundColor White
    Write-Host "  System Type: $(if ($SystemSpecs.SystemType.IsLaptop) { 'Laptop' } else { 'Desktop' })" -ForegroundColor White
    Write-Host "  Storage: $(if ($SystemSpecs.Storage.HasSSD) { 'SSD' } else { 'HDD' })" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Available Optimizations:" -ForegroundColor Yellow
    Write-Host "  1. System Performance (Power plan, Visual effects, Game DVR)" -ForegroundColor White
    Write-Host "  2. Bloatware Removal (Remove unnecessary Windows apps)" -ForegroundColor White
    Write-Host "  3. Services Optimization (Disable unnecessary services)" -ForegroundColor White
    Write-Host "  4. GPU Optimization (NVIDIA/AMD/Intel specific)" -ForegroundColor White
    Write-Host "  5. Network Optimization (TCP/IP, QoS settings)" -ForegroundColor White
    Write-Host "  6. Storage Optimization (SSD/HDD specific)" -ForegroundColor White
    Write-Host "  7. Memory Optimization (Page file, memory compression)" -ForegroundColor White
    Write-Host "  8. Windows Update (Configure update behavior)" -ForegroundColor White
    Write-Host "  9. Privacy Settings (Telemetry, data collection)" -ForegroundColor White
    Write-Host "  10. Security Optimization (Windows Defender)" -ForegroundColor White
    Write-Host "  11. Startup Optimization (Analyze startup programs)" -ForegroundColor White
    Write-Host ""
    Write-Host "  12. Optimize All (Apply all optimizations)" -ForegroundColor Green
    Write-Host "  0. Exit" -ForegroundColor Red
    Write-Host ""
}

function Start-CLIInterface {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs
    )
    
    Write-OptimizationLog "Starting CLI interface..." "INFO"
    
    # Initialize backup system
    Write-Host "Creating backups before making changes..." -ForegroundColor Yellow
    $backupResult = Initialize-BackupSystem
    
    if (-not $backupResult.RestorePoint) {
        $continue = Read-Host "Warning: Could not create system restore point. Continue anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            Write-OptimizationLog "User cancelled due to backup failure" "INFO"
            return
        }
    }
    
    $selectedOptions = @{}
    $running = $true
    
    while ($running) {
        Show-CLIMenu -SystemSpecs $SystemSpecs
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-Host "`nApplying System Performance optimizations..." -ForegroundColor Cyan
                $result = Optimize-SystemPerformance -SystemSpecs $SystemSpecs -Options @{
                    PowerPlan = $true
                    VisualEffects = $true
                    DisableGameDVR = $true
                }
                Write-Host "Completed! Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                Write-Host "`nRemoving bloatware applications..." -ForegroundColor Cyan
                $confirm = Read-Host "This will remove common Windows Store apps. Continue? (Y/N)"
                if ($confirm -eq "Y" -or $confirm -eq "y") {
                    $result = Remove-BloatwareApps -SystemSpecs $SystemSpecs
                    Write-Host "Removed $($result.Removed) apps. Press any key to continue..." -ForegroundColor Green
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "3" {
                Write-Host "`nOptimizing Windows services..." -ForegroundColor Cyan
                $result = Optimize-Services -SystemSpecs $SystemSpecs
                Write-Host "Disabled $($result.Disabled) services. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Write-Host "`nOptimizing GPU settings..." -ForegroundColor Cyan
                $result = Optimize-GPU -SystemSpecs $SystemSpecs
                Write-Host "GPU optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                Write-Host "`nOptimizing network settings..." -ForegroundColor Cyan
                $result = Optimize-Network -SystemSpecs $SystemSpecs
                Write-Host "Network optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                Write-Host "`nOptimizing storage settings..." -ForegroundColor Cyan
                $result = Optimize-Storage -SystemSpecs $SystemSpecs
                Write-Host "Storage optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" {
                Write-Host "`nOptimizing memory settings..." -ForegroundColor Cyan
                $result = Optimize-Memory -SystemSpecs $SystemSpecs
                Write-Host "Memory optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" {
                Write-Host "`nOptimizing Windows Update settings..." -ForegroundColor Cyan
                $result = Optimize-WindowsUpdate -SystemSpecs $SystemSpecs
                Write-Host "Windows Update optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "9" {
                Write-Host "`nOptimizing privacy settings..." -ForegroundColor Cyan
                $result = Optimize-Privacy -SystemSpecs $SystemSpecs
                Write-Host "Privacy optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "10" {
                Write-Host "`nOptimizing security settings..." -ForegroundColor Cyan
                $result = Optimize-Security -SystemSpecs $SystemSpecs
                Write-Host "Security optimization completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "11" {
                Write-Host "`nAnalyzing startup programs..." -ForegroundColor Cyan
                $result = Optimize-Startup -SystemSpecs $SystemSpecs
                Write-Host "Startup analysis completed. Press any key to continue..." -ForegroundColor Green
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "12" {
                Write-Host "`nThis will apply ALL optimizations. Are you sure? (Y/N)" -ForegroundColor Yellow
                $confirm = Read-Host
                if ($confirm -eq "Y" -or $confirm -eq "y") {
                    Write-Host "`nApplying all optimizations..." -ForegroundColor Cyan
                    
                    Optimize-SystemPerformance -SystemSpecs $SystemSpecs -Options @{ PowerPlan = $true; VisualEffects = $true; DisableGameDVR = $true }
                    Remove-BloatwareApps -SystemSpecs $SystemSpecs
                    Optimize-Services -SystemSpecs $SystemSpecs
                    Optimize-GPU -SystemSpecs $SystemSpecs
                    Optimize-Network -SystemSpecs $SystemSpecs
                    Optimize-Storage -SystemSpecs $SystemSpecs
                    Optimize-Memory -SystemSpecs $SystemSpecs
                    Optimize-WindowsUpdate -SystemSpecs $SystemSpecs
                    Optimize-Privacy -SystemSpecs $SystemSpecs
                    Optimize-Security -SystemSpecs $SystemSpecs
                    Optimize-Startup -SystemSpecs $SystemSpecs
                    
                    Write-Host "`nAll optimizations completed! Press any key to continue..." -ForegroundColor Green
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "0" {
                $running = $false
            }
            default {
                Write-Host "Invalid option. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
    
    # Generate summary report
    Write-Host "`nGenerating optimization summary..." -ForegroundColor Cyan
    $summary = Generate-OptimizationSummary -SystemSpecs $SystemSpecs
    Write-Host "Summary saved to: $($script:AppConfig.SummaryReport)" -ForegroundColor Green
    Write-Host "`nThank you for using Windows Optimization Script!" -ForegroundColor Cyan
}

#endregion

#region Summary and Reporting

function Generate-OptimizationSummary {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs
    )
    
    $summary = @"
========================================
Windows Optimization Summary Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

System Information:
-------------------
CPU: $($SystemSpecs.CPU.Name)
  - Cores: $($SystemSpecs.CPU.Cores)
  - Threads: $($SystemSpecs.CPU.Threads)
  - Architecture: $($SystemSpecs.CPU.Architecture)

RAM: $($SystemSpecs.RAM.TotalGB) GB total
  - Available: $($SystemSpecs.RAM.AvailableGB) GB

GPU: $($SystemSpecs.GPU.Primary)
  - NVIDIA: $($SystemSpecs.GPU.NVIDIA)
  - AMD: $($SystemSpecs.GPU.AMD)
  - Intel: $($SystemSpecs.GPU.Intel)

Storage:
  - SSD: $($SystemSpecs.Storage.HasSSD)
  - NVMe: $($SystemSpecs.Storage.HasNVMe)
  - HDD: $($SystemSpecs.Storage.HasHDD)

OS: $($SystemSpecs.OS.Name)
  - Version: $($SystemSpecs.OS.Version)
  - Build: $($SystemSpecs.OS.Build)
  - Edition: $($SystemSpecs.OS.Edition)

System Type: $(if ($SystemSpecs.SystemType.IsLaptop) { 'Laptop' } else { 'Desktop' })
  - Has Battery: $($SystemSpecs.SystemType.HasBattery)

Optimization Details:
---------------------
All changes have been logged to: $($script:AppConfig.ChangesLog)
Backups are stored in: $($script:AppConfig.BackupDir)
Full log file: $($script:AppConfig.LogFile)

Next Steps:
-----------
1. Review the changes log for details of all modifications
2. Restart your computer for all changes to take full effect
3. Monitor system performance and stability
4. Use System Restore if you encounter any issues

For support or to report issues, please refer to the log files.

========================================
"@
    
    $summary | Out-File -FilePath $script:AppConfig.SummaryReport -Encoding UTF8
    return $summary
}

#endregion

#region GUI Interface

function Start-GUIInterface {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SystemSpecs
    )
    
    Write-OptimizationLog "Starting GUI interface..." "INFO"
    
    # Load required assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create main form
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text = "$($script:AppConfig.Name) v$($script:AppConfig.Version)"
    $mainForm.Size = New-Object System.Drawing.Size(1000, 750)
    $mainForm.StartPosition = "CenterScreen"
    $mainForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $mainForm.ForeColor = [System.Drawing.Color]::White
    $mainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $mainForm.MaximizeBox = $false
    
    # Header panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Size = New-Object System.Drawing.Size(1000, 80)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $mainForm.Controls.Add($headerPanel)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $script:AppConfig.Name
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 35)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $headerPanel.Controls.Add($titleLabel)
    
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "Version $($script:AppConfig.Version)"
    $versionLabel.Location = New-Object System.Drawing.Point(25, 50)
    $versionLabel.Size = New-Object System.Drawing.Size(400, 20)
    $versionLabel.ForeColor = [System.Drawing.Color]::LightGray
    $headerPanel.Controls.Add($versionLabel)
    
    # System info panel
    $infoPanel = New-Object System.Windows.Forms.Panel
    $infoPanel.Location = New-Object System.Drawing.Point(10, 90)
    $infoPanel.Size = New-Object System.Drawing.Size(980, 120)
    $infoPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $infoPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $mainForm.Controls.Add($infoPanel)
    
    $infoTitle = New-Object System.Windows.Forms.Label
    $infoTitle.Text = "System Information"
    $infoTitle.Location = New-Object System.Drawing.Point(10, 10)
    $infoTitle.Size = New-Object System.Drawing.Size(200, 20)
    $infoTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $infoTitle.ForeColor = [System.Drawing.Color]::White
    $infoPanel.Controls.Add($infoTitle)
    
    $infoText = "CPU: $($SystemSpecs.CPU.Name) | RAM: $($SystemSpecs.RAM.TotalGB) GB | GPU: $($SystemSpecs.GPU.Primary) | OS: $($SystemSpecs.OS.Name) Build $($SystemSpecs.OS.Build) | Type: $(if ($SystemSpecs.SystemType.IsLaptop) { 'Laptop' } else { 'Desktop' })"
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = $infoText
    $infoLabel.Location = New-Object System.Drawing.Point(10, 35)
    $infoLabel.Size = New-Object System.Drawing.Size(960, 80)
    $infoLabel.ForeColor = [System.Drawing.Color]::LightGray
    $infoPanel.Controls.Add($infoLabel)
    
    # Optimization options panel
    $optionsPanel = New-Object System.Windows.Forms.Panel
    $optionsPanel.Location = New-Object System.Drawing.Point(10, 220)
    $optionsPanel.Size = New-Object System.Drawing.Size(480, 450)
    $optionsPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $optionsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $mainForm.Controls.Add($optionsPanel)
    
    $optionsTitle = New-Object System.Windows.Forms.Label
    $optionsTitle.Text = "Optimization Options"
    $optionsTitle.Location = New-Object System.Drawing.Point(10, 10)
    $optionsTitle.Size = New-Object System.Drawing.Size(200, 20)
    $optionsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $optionsTitle.ForeColor = [System.Drawing.Color]::White
    $optionsPanel.Controls.Add($optionsTitle)
    
    # Checkboxes for optimizations
    $checkboxes = @{}
    $yPos = 40
    $options = @(
        @{Key="SystemPerformance"; Text="System Performance (Power plan, Visual effects, Game DVR)"; Impact="Low"},
        @{Key="Bloatware"; Text="Bloatware Removal"; Impact="Low"},
        @{Key="Services"; Text="Services Optimization"; Impact="Medium"},
        @{Key="GPU"; Text="GPU Optimization"; Impact="Medium"},
        @{Key="Network"; Text="Network Optimization"; Impact="Medium"},
        @{Key="Storage"; Text="Storage Optimization"; Impact="Medium"},
        @{Key="Memory"; Text="Memory Optimization"; Impact="Medium"},
        @{Key="WindowsUpdate"; Text="Windows Update Configuration"; Impact="Low"},
        @{Key="Privacy"; Text="Privacy Settings"; Impact="Low"},
        @{Key="Security"; Text="Security Optimization"; Impact="Low"},
        @{Key="Startup"; Text="Startup Analysis"; Impact="Low"}
    )
    
    foreach ($option in $options) {
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = "$($option.Text) [$($option.Impact)]"
        $chk.Location = New-Object System.Drawing.Point(20, $yPos)
        $chk.Size = New-Object System.Drawing.Size(440, 25)
        $chk.ForeColor = [System.Drawing.Color]::White
        $chk.BackColor = [System.Drawing.Color]::Transparent
        $chk.Checked = $false
        $optionsPanel.Controls.Add($chk)
        $checkboxes[$option.Key] = $chk
        $yPos += 30
    }
    
    # Action buttons panel
    $actionPanel = New-Object System.Windows.Forms.Panel
    $actionPanel.Location = New-Object System.Drawing.Point(500, 220)
    $actionPanel.Size = New-Object System.Drawing.Size(490, 450)
    $actionPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $actionPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $mainForm.Controls.Add($actionPanel)
    
    $actionTitle = New-Object System.Windows.Forms.Label
    $actionTitle.Text = "Actions"
    $actionTitle.Location = New-Object System.Drawing.Point(10, 10)
    $actionTitle.Size = New-Object System.Drawing.Size(200, 20)
    $actionTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $actionTitle.ForeColor = [System.Drawing.Color]::White
    $actionPanel.Controls.Add($actionTitle)
    
    # Status/Log textbox
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 40)
    $statusTextBox.Size = New-Object System.Drawing.Size(470, 350)
    $statusTextBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $statusTextBox.ForeColor = [System.Drawing.Color]::LightGreen
    $statusTextBox.ReadOnly = $true
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $actionPanel.Controls.Add($statusTextBox)
    
    # Function to update status
    $updateStatus = {
        param([string]$message)
        $statusTextBox.AppendText("$message`r`n")
        $statusTextBox.SelectionStart = $statusTextBox.Text.Length
        $statusTextBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    # Optimize Selected button
    $btnOptimize = New-Object System.Windows.Forms.Button
    $btnOptimize.Text = "Apply Selected Optimizations"
    $btnOptimize.Location = New-Object System.Drawing.Point(10, 400)
    $btnOptimize.Size = New-Object System.Drawing.Size(230, 35)
    $btnOptimize.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnOptimize.ForeColor = [System.Drawing.Color]::White
    $btnOptimize.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOptimize.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $actionPanel.Controls.Add($btnOptimize)
    
    # Optimize All button
    $btnOptimizeAll = New-Object System.Windows.Forms.Button
    $btnOptimizeAll.Text = "Optimize All"
    $btnOptimizeAll.Location = New-Object System.Drawing.Point(250, 400)
    $btnOptimizeAll.Size = New-Object System.Drawing.Size(230, 35)
    $btnOptimizeAll.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
    $btnOptimizeAll.ForeColor = [System.Drawing.Color]::White
    $btnOptimizeAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOptimizeAll.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $actionPanel.Controls.Add($btnOptimizeAll)
    
    # Exit button
    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Text = "Exit"
    $btnExit.Location = New-Object System.Drawing.Point(10, 445)
    $btnExit.Size = New-Object System.Drawing.Size(470, 30)
    $btnExit.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
    $btnExit.ForeColor = [System.Drawing.Color]::White
    $btnExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $actionPanel.Controls.Add($btnExit)
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 680)
    $progressBar.Size = New-Object System.Drawing.Size(980, 25)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $mainForm.Controls.Add($progressBar)
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "Ready"
    $statusLabel.Location = New-Object System.Drawing.Point(10, 710)
    $statusLabel.Size = New-Object System.Drawing.Size(980, 20)
    $statusLabel.ForeColor = [System.Drawing.Color]::LightGray
    $mainForm.Controls.Add($statusLabel)
    
    # Initialize backup system
    $script:backupResult = $null
    $script:backupInitialized = $false
    
    $initBackup = {
        if (-not $script:backupInitialized) {
            $updateStatus.Invoke("Initializing backup system...")
            $script:backupResult = Initialize-BackupSystem
            $script:backupInitialized = $true
            if ($script:backupResult.RestorePoint) {
                $updateStatus.Invoke("System restore point created successfully.")
            } else {
                $updateStatus.Invoke("Warning: Could not create system restore point.")
            }
            $updateStatus.Invoke("Backup system ready.`r`n")
        }
    }
    
    # Optimize Selected button click
    $btnOptimize.Add_Click({
        $initBackup.Invoke()
        
        $selected = @{}
        foreach ($key in $checkboxes.Keys) {
            if ($checkboxes[$key].Checked) {
                $selected[$key] = $true
            }
        }
        
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one optimization option.", "No Selection", "OK", "Warning")
            return
        }
        
        $statusLabel.Text = "Applying optimizations..."
        $progressBar.Value = 0
        $updateStatus.Invoke("Starting optimizations...")
        
        $total = $selected.Count
        $current = 0
        
        if ($selected.ContainsKey("SystemPerformance")) {
            $updateStatus.Invoke("Applying System Performance optimizations...")
            Optimize-SystemPerformance -SystemSpecs $SystemSpecs -Options @{ PowerPlan = $true; VisualEffects = $true; DisableGameDVR = $true }
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Bloatware")) {
            $updateStatus.Invoke("Removing bloatware...")
            Remove-BloatwareApps -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Services")) {
            $updateStatus.Invoke("Optimizing services...")
            Optimize-Services -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("GPU")) {
            $updateStatus.Invoke("Optimizing GPU...")
            Optimize-GPU -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Network")) {
            $updateStatus.Invoke("Optimizing network...")
            Optimize-Network -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Storage")) {
            $updateStatus.Invoke("Optimizing storage...")
            Optimize-Storage -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Memory")) {
            $updateStatus.Invoke("Optimizing memory...")
            Optimize-Memory -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("WindowsUpdate")) {
            $updateStatus.Invoke("Configuring Windows Update...")
            Optimize-WindowsUpdate -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Privacy")) {
            $updateStatus.Invoke("Optimizing privacy settings...")
            Optimize-Privacy -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Security")) {
            $updateStatus.Invoke("Optimizing security...")
            Optimize-Security -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        if ($selected.ContainsKey("Startup")) {
            $updateStatus.Invoke("Analyzing startup...")
            Optimize-Startup -SystemSpecs $SystemSpecs
            $current++
            $progressBar.Value = [Math]::Round(($current / $total) * 100)
        }
        
        $progressBar.Value = 100
        $statusLabel.Text = "Optimizations completed!"
        $updateStatus.Invoke("`r`nAll selected optimizations completed successfully!")
        $updateStatus.Invoke("Summary report: $($script:AppConfig.SummaryReport)")
        
        Generate-OptimizationSummary -SystemSpecs $SystemSpecs | Out-Null
        
        [System.Windows.Forms.MessageBox]::Show("Optimizations completed successfully!`r`n`r`nSummary report saved to:`r`n$($script:AppConfig.SummaryReport)", "Success", "OK", "Information")
    })
    
    # Optimize All button click
    $btnOptimizeAll.Add_Click({
        $result = [System.Windows.Forms.MessageBox]::Show("This will apply ALL optimizations. Continue?", "Confirm", "YesNo", "Question")
        if ($result -eq "Yes") {
            # Check all boxes
            foreach ($chk in $checkboxes.Values) {
                $chk.Checked = $true
            }
            # Trigger optimize selected
            $btnOptimize.PerformClick()
        }
    })
    
    # Exit button click
    $btnExit.Add_Click({
        $mainForm.Close()
    })
    
    # Form load
    $mainForm.Add_Shown({
        $updateStatus.Invoke("Windows Optimization Script v$($script:AppConfig.Version)")
        $updateStatus.Invoke("System detected: $($SystemSpecs.CPU.Name)")
        $updateStatus.Invoke("Ready to optimize. Select options and click 'Apply Selected Optimizations'`r`n")
        $statusLabel.Text = "Ready - Select optimization options"
    })
    
    # Show form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $mainForm.ShowDialog() | Out-Null
}

#endregion

#region Main Entry Point

# Main execution
Write-OptimizationLog "========================================" "INFO"
Write-OptimizationLog "Windows Optimization Script v$($script:AppConfig.Version)" "INFO"
Write-OptimizationLog "========================================" "INFO"
Write-OptimizationLog "Starting initialization..." "INFO"

# Detect system specifications
$systemSpecs = Get-SystemSpecifications

# Determine interface mode
if ($script:IsGUI) {
    try {
        $guiChoice = Read-Host "`nLaunch GUI interface? (Y/N, default: N)"
        if ($guiChoice -eq "Y" -or $guiChoice -eq "y") {
            Start-GUIInterface -SystemSpecs $systemSpecs
        } else {
            Start-CLIInterface -SystemSpecs $systemSpecs
        }
    } catch {
        Write-OptimizationLog "Error with GUI choice, using CLI: $_" "WARNING"
        Start-CLIInterface -SystemSpecs $systemSpecs
    }
} else {
    # CLI mode
    Start-CLIInterface -SystemSpecs $systemSpecs
}

Write-OptimizationLog "Script execution completed." "INFO"

#endregion
