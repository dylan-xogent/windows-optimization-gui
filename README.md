# Windows Optimization Script

A comprehensive Windows optimization tool that detects system specifications and applies appropriate optimizations conservatively with full backup/restore capabilities. Supports both CLI and GUI interfaces.

## Features

- **Spec-Aware Optimizations**: Automatically detects your system hardware (CPU, RAM, GPU, Storage) and applies appropriate optimizations
- **Conservative Approach**: All changes are logged, backed up, and reversible
- **Dual Interface**: Choose between Command-Line Interface (CLI) or Graphical User Interface (GUI)
- **Comprehensive Backup System**: Creates system restore points and backs up registry keys before making changes
- **Modular Design**: Select specific optimizations or apply all at once
- **Windows 10/11 Support**: Optimized for both Windows 10 and Windows 11

## Quick Start

### Launch from GitHub

Run this command in an elevated PowerShell window:

```powershell
iex (irm 'https://raw.githubusercontent.com/[user]/[repo]/main/windows-optimization-gui.ps1')
```

**Note**: Replace `[user]` and `[repo]` with your actual GitHub username and repository name.

### Local Installation

1. Clone or download this repository
2. Open PowerShell as Administrator
3. Navigate to the script directory
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -File windows-optimization-gui.ps1
```

## System Requirements

- **OS**: Windows 10 or Windows 11
- **PowerShell**: Version 5.1 or higher (included with Windows 10/11)
- **Privileges**: Administrator rights required
- **Internet**: Optional (only needed if launching from GitHub)

## Optimization Categories

### 1. System Performance
- Power plan optimization (High Performance for Desktop, Balanced for Laptop)
- Visual effects optimization
- Disable Game DVR and Game Bar
- **Impact**: Low | **Risk**: Low

### 2. Bloatware Removal
- Removes common Windows Store apps that are not essential
- User-selectable app list
- **Impact**: Low | **Risk**: Low

### 3. Services Optimization
- Disables unnecessary Windows services
- Conservative list (services are disabled, not deleted)
- Laptop-aware (preserves battery-related services)
- **Impact**: Medium | **Risk**: Medium

### 4. GPU Optimization
- NVIDIA-specific optimizations
- AMD-specific optimizations
- Intel Graphics optimizations
- Only applies relevant optimizations based on detected GPU
- **Impact**: Medium | **Risk**: Medium

### 5. Network Optimization
- TCP/IP settings optimization
- QoS (Quality of Service) configuration
- Latency reduction tweaks
- **Impact**: Medium | **Risk**: Medium

### 6. Storage Optimization
- SSD-specific optimizations (TRIM, disable defrag)
- HDD-specific optimizations (defrag schedule)
- Superfetch/Prefetch configuration
- **Impact**: Medium | **Risk**: Medium

### 7. Memory Optimization
- Virtual memory/page file optimization
- Memory compression settings (for high RAM systems)
- RAM-aware configurations
- **Impact**: Medium | **Risk**: Medium

### 8. Windows Update
- Configure update behavior for manual control
- Conservative settings (notify before download)
- **Impact**: Low | **Risk**: Low

### 9. Privacy Settings
- Telemetry configuration
- Data collection settings
- Conservative approach
- **Impact**: Low | **Risk**: Low

### 10. Security Optimization
- Windows Defender recommendations
- Security best practices
- **Impact**: Low | **Risk**: Low

### 11. Startup Analysis
- Analyzes startup programs
- Provides recommendations
- **Impact**: Low | **Risk**: Low

## Usage

### CLI Mode

When you run the script, you'll see an interactive menu:

```
========================================
  Windows Optimization Script v2.0.0
========================================

System Information:
  CPU: Intel Core i7-9700K
  RAM: 16 GB
  GPU: NVIDIA GeForce RTX 3070
  OS: Microsoft Windows 11 Pro Build 22621
  System Type: Desktop
  Storage: SSD

Available Optimizations:
  1. System Performance (Power plan, Visual effects, Game DVR)
  2. Bloatware Removal (Remove unnecessary Windows apps)
  3. Services Optimization (Disable unnecessary services)
  ...
  12. Optimize All (Apply all optimizations)
  0. Exit
```

Select an option by entering its number, or choose "12" to apply all optimizations.

### GUI Mode

If GUI is available, you'll be prompted to launch it. The GUI provides:

- **System Information Panel**: Displays detected hardware and software
- **Optimization Options**: Checkboxes for each optimization category with impact levels
- **Action Panel**: Real-time status log and action buttons
- **Progress Tracking**: Visual progress bar and status updates

## Backup and Restore

### Automatic Backups

Before making any changes, the script automatically:

1. **Creates a System Restore Point**: Allows you to restore your system to a previous state
2. **Backs up Registry Keys**: Critical registry keys are exported to backup files
3. **Backs up Service States**: Current service configurations are saved

### Backup Locations

- **System Restore Points**: Managed by Windows System Restore
- **Registry Backups**: `%USERPROFILE%\Documents\WindowsOptimization\Backups\`
- **Service State Backups**: `%USERPROFILE%\Documents\WindowsOptimization\Backups\Services_[timestamp].json`
- **Change Log**: `%USERPROFILE%\Documents\WindowsOptimization\Changes.log`
- **Summary Report**: `%USERPROFILE%\Documents\WindowsOptimization\OptimizationSummary.txt`

### Restoring Changes

If you need to revert changes:

1. **System Restore**: Use Windows System Restore to restore to the point created before optimization
2. **Registry Restore**: Import the `.reg` files from the Backups folder
3. **Manual Review**: Check the Changes.log file to see what was modified

## Spec-Aware Optimizations

The script automatically adapts optimizations based on your system:

### Laptop vs Desktop
- **Laptop**: Uses Balanced power plan, preserves battery-related services
- **Desktop**: Uses High Performance power plan, maximum performance optimizations

### RAM-Based Optimizations
- **< 8GB**: Aggressive memory optimizations, larger page file
- **8-16GB**: Standard memory optimizations
- **≥ 16GB**: Reduced page file, disables memory compression

### Storage-Based Optimizations
- **SSD**: Enables TRIM, disables defragmentation, disables Superfetch
- **HDD**: Optimizes defragmentation schedule, enables Superfetch
- **NVMe**: Additional NVMe-specific optimizations

### GPU-Specific Optimizations
- **NVIDIA**: Applies NVIDIA registry tweaks and driver optimizations
- **AMD**: Applies AMD-specific optimizations
- **Intel**: Applies Intel Graphics optimizations
- Only relevant optimizations are applied

## Logging

All operations are logged for transparency and troubleshooting:

- **Operation Log**: `%TEMP%\WindowsOptimization_[timestamp].log`
- **Change Log**: `%USERPROFILE%\Documents\WindowsOptimization\Changes.log`
- **Summary Report**: Generated after optimization completes

## Safety and Best Practices

### Conservative Approach

- All changes are logged with before/after values
- Registry changes are backed up before modification
- Services are disabled (not deleted) - can be re-enabled
- Reversible operations only
- Clear warnings for potentially impactful changes

### Recommendations

1. **Create a System Restore Point**: The script does this automatically, but ensure System Restore is enabled
2. **Review Changes**: Check the Changes.log file after optimization
3. **Test System**: After optimization, test your system to ensure everything works correctly
4. **Restart**: Some changes require a system restart to take full effect
5. **Monitor Performance**: Monitor your system performance after optimization

## Troubleshooting

### Script Won't Run

- **Check PowerShell Version**: Run `$PSVersionTable.PSVersion` - should be 5.1 or higher
- **Run as Administrator**: Right-click PowerShell and select "Run as Administrator"
- **Execution Policy**: If blocked, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### System Restore Point Creation Failed

- **Enable System Restore**: Ensure System Restore is enabled on your system drive
- **Check Disk Space**: Ensure you have sufficient disk space for restore points
- **Manual Creation**: You can manually create a restore point before running the script

### Some Optimizations Didn't Apply

- **Check Logs**: Review the log files for error messages
- **Permissions**: Ensure you're running as Administrator
- **System State**: Some optimizations may not apply if services/features are not available

## Contributing

Contributions are welcome! Please ensure:

- Code follows PowerShell best practices
- All changes are conservative and reversible
- Comprehensive logging is included
- Documentation is updated

## License

This script is provided as-is for educational and personal use. Use at your own risk.

## Disclaimer

This script modifies Windows system settings. While all changes are conservative and reversible, use at your own risk. The authors are not responsible for any issues that may arise from using this script. Always create backups before making system changes.

## Support

For issues, questions, or contributions:

1. Check the log files for detailed error information
2. Review the Changes.log to see what was modified
3. Use System Restore if you encounter issues
4. Open an issue on GitHub with relevant log information

## Version History

### Version 2.0.0
- Complete redesign with spec-aware optimizations
- Added CLI and GUI interfaces
- Comprehensive backup system
- Modular optimization functions
- Windows 10/11 support
- GitHub launch support

---

**Note**: Replace `[user]` and `[repo]` in the GitHub launch command with your actual GitHub username and repository name.
