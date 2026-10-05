# Windows Optimization Script v3.0

🚀 **A COMPREHENSIVE, INTELLIGENT Windows optimization tool with hardware-aware optimizations, complete backup/restore capabilities, performance benchmarking, and beautiful HTML reporting.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ What's New in v3.0

### 🎯 Major Features Added

- ✅ **Complete Rollback System** - Full restore functionality with backup selection
- ✅ **Performance Benchmarking** - Before/after performance metrics
- ✅ **Beautiful HTML Reports** - Professional optimization reports with visual comparisons
- ✅ **Optimization Profiles** - Gaming, Productivity, Privacy, and Battery Saver presets
- ✅ **System State Validation** - Checks for pending reboots, disk space, Windows Update conflicts
- ✅ **Advanced Network Optimizations** - RSS, interrupt moderation, DNS configuration, adapter-specific tweaks
- ✅ **Gaming Detection & Optimization** - Auto-detects Steam, Epic, Origin, Battle.net
- ✅ **Advanced Storage Management** - Temp file cleanup, Storage Sense configuration
- ✅ **Actual Page File Configuration** - WMI-based page file management (not just recommendations!)
- ✅ **Fixed Critical Bugs** - Syntax errors, elevation logic, registry path validation

### 🔧 Bug Fixes

- Fixed critical syntax error causing script failures
- Fixed elevation logic for GitHub launch (iex/irm compatibility)
- Fixed registry path validation in backup system
- Implemented actual page file configuration (was only calculating before)

## 🌟 Features

### Core Capabilities

- **🧠 Spec-Aware Optimizations**: Automatically detects your hardware and applies intelligent, hardware-specific optimizations
- **🔒 Conservative & Safe**: All changes logged, backed up, and **100% reversible**
- **🎨 Dual Interface**: Choose between powerful CLI or beautiful GUI
- **💾 Complete Backup System**: System restore points, registry backups, service state backups
- **📊 Performance Benchmarking**: Measure actual performance improvements
- **📄 HTML Reports**: Beautiful, professional reports with before/after comparisons
- **🎮 Gaming Optimized**: Detects game platforms and applies gaming-specific tweaks
- **⚡ Profile-Based**: Quick apply with Gaming, Productivity, Privacy, or Battery Saver profiles
- **🔄 Full Rollback**: Restore any previous backup with one command
- **✅ System Validation**: Pre-checks for pending reboots, disk space, conflicts

## 🚀 Quick Start

### Method 1: Download, review, run

This script changes system settings, so read it before you run it. In an **elevated** PowerShell window:

```powershell
git clone https://github.com/dylan-xogent/windows-optimization-gui.git
cd windows-optimization-gui
# Review windows-optimization-gui.ps1, then:
powershell -ExecutionPolicy Bypass -File .\windows-optimization-gui.ps1
```

### Method 2: Local Installation

1. Clone or download this repository
2. Open PowerShell as Administrator (Right-click → Run as Administrator)
3. Navigate to the script directory
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -File windows-optimization-gui.ps1
```

## 📋 System Requirements

| Requirement | Specification |
|------------|---------------|
| **OS** | Windows 10 or Windows 11 |
| **PowerShell** | Version 5.1+ (included with Windows 10/11) |
| **Privileges** | Administrator rights required |
| **Internet** | Optional (only for GitHub launch) |
| **Disk Space** | 100MB+ free for backups |

## 🎯 Optimization Categories

### 1. 🚀 System Performance
- Power plan optimization (High Performance for Desktop, Balanced for Laptop)
- Visual effects optimization for better performance
- Game DVR and Game Bar management
- **Impact**: Low | **Risk**: Low

### 2. 🧹 Bloatware Removal
- Removes 30+ common Windows Store apps
- Includes: Xbox apps, Solitaire, Weather, Your Phone, Mixed Reality, Skype, etc.
- Removes both installed and provisioned packages
- **Impact**: Low | **Risk**: Low

### 3. ⚙️ Services Optimization
- Disables 7 conservative services (Fax, Windows Search, Remote Registry, etc.)
- Laptop-aware (preserves biometric service on laptops)
- Services are disabled, not deleted (fully reversible)
- **Impact**: Medium | **Risk**: Medium

### 4. 🎮 GPU Optimization
- **NVIDIA**: Registry tweaks, hardware-accelerated GPU scheduling
- **AMD**: AMD-specific power management optimizations
- **Intel**: Intel Graphics optimizations
- Only applies vendor-specific optimizations for detected hardware
- **Impact**: Medium | **Risk**: Medium

### 5. 🌐 Network Optimization
- Disables Nagle's Algorithm for lower latency
- TCP/IP parameter tuning (TcpAckFrequency, TCPNoDelay, Tcp1323Opts)
- QoS throttling disabled
- **ADVANCED (NEW)**: RSS configuration, interrupt moderation, DNS optimization
- **Impact**: Medium | **Risk**: Medium

### 6. 💽 Storage Optimization
- **SSD**: TRIM enabled, defrag disabled, Superfetch disabled
- **HDD**: Defragmentation optimization
- **NVMe**: NVMe-specific optimizations
- **ADVANCED (NEW)**: Temp file cleanup, Storage Sense configuration
- **Impact**: Medium | **Risk**: Medium

### 7. 🧠 Memory Optimization
- **RAM-based page file sizing**:
  - <8GB: 1.5x RAM
  - 8-16GB: 1x RAM
  - ≥16GB: 0.5x RAM
  - ≥32GB: Disabled
- **NEW**: Actual WMI-based page file configuration (requires restart)
- Memory compression disabled for high-RAM systems (≥16GB)
- **Impact**: Medium | **Risk**: Medium

### 8. 🔄 Windows Update
- Set to "Notify before download" (conservative)
- Maintains security while giving user control
- **Impact**: Low | **Risk**: Low

### 9. 🔐 Privacy Settings
- Telemetry set to Security level (conservative)
- Data collection minimization
- Not completely disabled (maintains Windows functionality)
- **Impact**: Low | **Risk**: Low

### 10. 🛡️ Security Optimization
- Windows Defender recommendations (doesn't disable Defender)
- Security best practices
- **Impact**: Low | **Risk**: Low

### 11. 🚦 Startup Optimization
- Analyzes startup programs (doesn't auto-disable)
- Provides recommendations
- **Impact**: Low | **Risk**: Low

### 12. 🎮 Gaming Optimizations (NEW)
- Auto-detects Steam, Epic Games, Origin, Battle.net, Xbox Games
- Enables Windows Game Mode
- Optimizes fullscreen mode for better FPS
- Gaming-specific optimizations
- **Impact**: Low | **Risk**: Low

### 13. 🌐 Advanced Network (NEW)
- RSS (Receive Side Scaling) configuration
- Interrupt moderation optimization
- Network adapter power saving disabled
- Optional DNS configuration (Cloudflare 1.1.1.1 or Google 8.8.8.8)
- **Impact**: Medium | **Risk**: Low

### 14. 💾 Advanced Storage (NEW)
- Temporary files cleanup (Windows Temp, Prefetch)
- Storage Sense auto-configuration
- Disk space recovery
- **Impact**: Low | **Risk**: Low

## 🎨 Optimization Profiles (NEW)

Quickly apply optimized settings for your use case:

### 🎮 Gaming Profile
Perfect for gamers wanting maximum performance:
- ✅ System Performance (power, visual effects)
- ✅ Bloatware Removal
- ✅ Services Optimization
- ✅ GPU Optimization
- ✅ Network Optimization
- ✅ Storage + Memory Optimization
- ✅ Privacy Settings
- ✅ Gaming Optimizations
- ⏭️ Skips: Windows Update, Security, Game DVR

### 💼 Productivity Profile
Optimized for work and productivity:
- ✅ System Performance (balanced)
- ✅ Bloatware Removal
- ✅ Services + Network Optimization
- ✅ Storage + Memory Optimization
- ✅ Windows Update + Privacy
- ⏭️ Skips: GPU optimization, Game DVR disabled

### 🔐 Privacy Profile
Maximum privacy with minimal performance impact:
- ✅ Bloatware Removal
- ✅ Services Optimization
- ✅ Privacy Settings (maximum)
- ✅ Windows Update (controlled)
- ⏭️ Skips: Performance tweaks, GPU, Gaming

### 🔋 Battery Saver Profile
Optimized for laptops to extend battery life:
- ✅ Balanced power plan
- ✅ Bloatware Removal
- ✅ Services Optimization
- ✅ Storage Optimization
- ✅ Privacy Settings
- ⏭️ Skips: GPU, Network optimizations, memory tweaks

## 💻 Usage

### CLI Mode

When you run the script, you'll see an interactive menu:

```
========================================
  Windows Optimization Script v3.0.0
========================================

System Information:
  CPU: Intel Core i7-9700K (8 cores, 8 threads)
  RAM: 16 GB
  GPU: NVIDIA GeForce RTX 3070
  OS: Microsoft Windows 11 Pro Build 22621
  System Type: Desktop
  Storage: SSD

Available Optimizations:
  1. System Performance (Power plan, Visual effects, Game DVR)
  2. Bloatware Removal (Remove unnecessary Windows apps)
  3. Services Optimization (Disable unnecessary services)
  4. GPU Optimization (NVIDIA/AMD/Intel specific)
  5. Network Optimization (TCP/IP, QoS settings)
  6. Storage Optimization (SSD/HDD specific)
  7. Memory Optimization (Page file, memory compression)
  8. Windows Update (Configure update behavior)
  9. Privacy Settings (Telemetry, data collection)
  10. Security Optimization (Windows Defender)
  11. Startup Optimization (Analyze startup programs)

  12. Optimize All (Apply all optimizations)
  0. Exit
```

### GUI Mode

The modern GUI provides:

- **📊 System Information Panel**: Displays detected hardware specs
- **✅ Optimization Options**: Checkboxes for each category with impact levels
- **📝 Real-time Status Log**: See what's happening live
- **📈 Progress Tracking**: Visual progress bar
- **🎨 Modern Dark Theme**: Easy on the eyes
- **🖱️ One-Click Actions**: "Apply Selected" or "Optimize All"

## 💾 Backup and Restore

### Automatic Backups

Before making changes, the script automatically:

1. **Creates System Restore Point** ✅
2. **Backs up Registry Keys** ✅
3. **Backs up Service States** ✅
4. **Captures Performance Baseline** ✅ (NEW)

### Backup Locations

```
%USERPROFILE%\Documents\WindowsOptimization\
├── Backups\
│   ├── Services_[timestamp].json
│   ├── [RegistryKey]_[timestamp].reg
│   └── PerformanceBaseline_[timestamp].json
├── Changes.log
├── OptimizationSummary.txt
└── OptimizationReport.html (NEW)
```

### 🔄 Restoring Changes (NEW)

The script now includes a complete rollback system!

```powershell
# Use the built-in restore function
Restore-OptimizationBackup
```

This will:
- Show all available backup dates
- Let you select which backup to restore
- Restore services to previous state
- Restore registry keys from .reg files
- Provide detailed restoration log

## 📊 Performance Benchmarking (NEW)

The script now measures actual performance improvements!

### Metrics Captured:
- 🖥️ **CPU Usage** (idle percentage)
- 🧠 **Memory Usage** (GB used, percentage)
- 💽 **Disk Performance** (Read/Write MB/s)
- 🌐 **Network Latency** (ping to 8.8.8.8)
- ⏱️ **System Uptime** (since last boot)

### Before/After Comparison
```powershell
# Benchmark is captured automatically
# Before optimization: Captured
# After optimization: Captured
# Comparison: Generated in HTML report
```

## 📄 HTML Reports (NEW)

After optimization, a beautiful HTML report is automatically generated and opened in your browser:

### Report Includes:
- ✅ Complete system specifications
- ✅ Before/After performance comparison
- ✅ Visual performance improvements (charts)
- ✅ All changes applied (detailed list)
- ✅ Next steps and recommendations
- ✅ Professional design with gradients and cards
- ✅ Responsive layout

**Location**: `%USERPROFILE%\Documents\WindowsOptimization\OptimizationReport.html`

## ✅ System State Validation (NEW)

Before optimization, the script now checks:

- ⚠️ **Pending Reboots**: Warns if restart is needed
- 💽 **Disk Space**: Ensures enough space for backups (10GB+ recommended)
- 🔄 **Windows Update Status**: Checks if updates are in progress
- ✅ **System Health**: Overall system state validation

## 🧠 Spec-Aware Optimizations

The script intelligently adapts based on your hardware:

### Laptop vs Desktop
| Type | Power Plan | Services | Optimizations |
|------|-----------|----------|---------------|
| **Laptop** | Balanced | Preserves battery services | Battery-focused |
| **Desktop** | High Performance | Maximum optimization | Performance-focused |

### RAM-Based Optimizations
| RAM | Page File | Memory Compression | Strategy |
|-----|-----------|-------------------|----------|
| **< 8GB** | 1.5x RAM (e.g., 12GB) | Enabled | Aggressive memory management |
| **8-16GB** | 1x RAM (e.g., 16GB) | Enabled | Balanced approach |
| **16-32GB** | 0.5x RAM (e.g., 8GB) | **Disabled** | Reduced page file |
| **≥ 32GB** | **Disabled** | **Disabled** | Maximum RAM usage |

### Storage-Based Optimizations
| Type | TRIM | Defrag | Superfetch | Strategy |
|------|------|--------|-----------|----------|
| **NVMe SSD** | ✅ Enabled | ❌ Disabled | ❌ Disabled | Maximum SSD performance |
| **SATA SSD** | ✅ Enabled | ❌ Disabled | ❌ Disabled | SSD longevity |
| **HDD** | N/A | ✅ Enabled | ✅ Enabled | HDD optimization |

### GPU-Specific Optimizations
| Vendor | Optimizations Applied |
|--------|----------------------|
| **NVIDIA** | Registry tweaks, Hardware-accelerated GPU scheduling |
| **AMD** | Power management, AMD-specific registry settings |
| **Intel** | Intel Graphics optimizations |

## 📝 Logging

Comprehensive logging for transparency:

| Log File | Purpose | Location |
|----------|---------|----------|
| **Operation Log** | All operations with timestamps | `%TEMP%\WindowsOptimization_[timestamp].log` |
| **Change Log** | Before/after values for all changes | `%USERPROFILE%\Documents\WindowsOptimization\Changes.log` |
| **Summary Report** | Text summary of optimizations | `%USERPROFILE%\Documents\WindowsOptimization\OptimizationSummary.txt` |
| **HTML Report** | Beautiful visual report (NEW) | `%USERPROFILE%\Documents\WindowsOptimization\OptimizationReport.html` |

## 🛡️ Safety and Best Practices

### Our Conservative Approach

✅ **All changes are logged** with before/after values
✅ **Registry changes are backed up** before modification
✅ **Services are disabled**, not deleted (can be re-enabled)
✅ **Reversible operations only** - no destructive changes
✅ **Clear warnings** for potentially impactful changes
✅ **System restore point** created automatically
✅ **Full rollback system** for complete restoration

### Recommendations

1. ✅ **Enable System Restore**: Ensure System Restore is enabled on C: drive
2. 📝 **Review Changes**: Check Changes.log after optimization
3. 🧪 **Test System**: Verify everything works after optimization
4. 🔄 **Restart**: Some changes require restart (you'll be notified)
5. 📊 **Monitor Performance**: Check the HTML report for improvements
6. 💾 **Keep Backups**: Don't delete backup files for at least 30 days

## 🔧 Troubleshooting

### Script Won't Run

**Check PowerShell Version**:
```powershell
$PSVersionTable.PSVersion  # Should be 5.1 or higher
```

**Run as Administrator**:
- Right-click PowerShell → "Run as Administrator"

**Execution Policy Blocked**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Elevation Failed (Remote Execution)

The script automatically handles GitHub launch elevation by:
1. Detecting remote execution
2. Downloading script to temp location
3. Re-launching with admin privileges

If this fails, download the script locally and run as admin.

### System Restore Point Failed

**Enable System Restore**:
1. Right-click This PC → Properties
2. System Protection → Configure
3. Turn on system protection
4. Set disk usage (10GB+ recommended)

### Some Optimizations Didn't Apply

- 📝 **Check Logs**: Review log files for specific errors
- 🔒 **Permissions**: Ensure running as Administrator
- ⚙️ **System State**: Some features may not be available on your system
- 🔄 **Try Again**: Some optimizations may need retry

### Need to Revert Changes

**Option 1: Built-in Restore (NEW)**
```powershell
# Run the script again and use Restore function
Restore-OptimizationBackup
```

**Option 2: System Restore**
1. Open System Restore (rstrui.exe)
2. Select the restore point created before optimization
3. Follow the wizard

**Option 3: Manual Registry Restore**
1. Navigate to `%USERPROFILE%\Documents\WindowsOptimization\Backups\`
2. Double-click `.reg` files to restore registry keys

## 📊 Comparison: v2.0 → v3.0

| Feature | v2.0 | v3.0 |
|---------|------|------|
| **Optimization Categories** | 11 | 14 |
| **Rollback System** | ❌ | ✅ Full restore |
| **Performance Benchmarking** | ❌ | ✅ Before/After |
| **HTML Reports** | ❌ | ✅ Professional |
| **Optimization Profiles** | ❌ | ✅ 4 profiles |
| **System Validation** | ❌ | ✅ Pre-checks |
| **Page File Config** | ⚠️ Recommendation only | ✅ Actual WMI config |
| **Gaming Detection** | ❌ | ✅ Auto-detect |
| **Advanced Network** | Basic | ✅ RSS, DNS, more |
| **Advanced Storage** | Basic | ✅ Cleanup, Storage Sense |
| **Critical Bugs** | ⚠️ 4 bugs | ✅ All fixed |

## 🤝 Contributing

Contributions are welcome! Please ensure:

- ✅ Code follows PowerShell best practices
- ✅ All changes are conservative and reversible
- ✅ Comprehensive logging is included
- ✅ Documentation is updated
- ✅ Test on Windows 10 AND Windows 11

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This script modifies Windows system settings. While all changes are conservative and **100% reversible**, use at your own risk. The authors are not responsible for any issues that may arise. **Always create backups before making system changes.**

## 💬 Support

Need help? Here's how to get support:

1. 📝 **Check the log files** for detailed error information
2. 📊 **Review Changes.log** to see what was modified
3. 🔄 **Use Restore function** or System Restore if issues occur
4. 📖 **Read this README** for troubleshooting steps
5. 🐛 **Open an issue** on GitHub with relevant log information

## 📈 Version History

### Version 3.0.0 (Current)
- ✅ **Complete rollback system** with backup selection
- ✅ **Performance benchmarking** (before/after metrics)
- ✅ **Beautiful HTML reports** with visual comparisons
- ✅ **Optimization profiles** (Gaming, Productivity, Privacy, Battery Saver)
- ✅ **System state validation** (pending reboots, disk space, conflicts)
- ✅ **Advanced network optimizations** (RSS, interrupt moderation, DNS)
- ✅ **Gaming detection & optimization** (Steam, Epic, Origin, Battle.net)
- ✅ **Advanced storage management** (temp cleanup, Storage Sense)
- ✅ **Actual page file configuration** (WMI-based)
- ✅ **Fixed critical bugs** (syntax, elevation, registry paths)

### Version 2.0.0
- Complete redesign with spec-aware optimizations
- Added CLI and GUI interfaces
- Comprehensive backup system
- Modular optimization functions
- Windows 10/11 support
- GitHub launch support

---

## 🎉 Get Started

See [Quick Start](#-quick-start) above. The script includes backup and restore options for the changes it makes.

---

<p align="center">
  <strong>Made with ❤️ for the Windows optimization community</strong><br>
  <sub>Star ⭐ this repo if you found it helpful!</sub>
</p>
