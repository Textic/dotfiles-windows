# File: scripts/07_uninstalls.ps1
# Description: Manages explicit uninstallation of unwanted applications and bloatware packages.

# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

Write-Log "Starting uninstalls module..."

if (Request-Confirmation "Do you want to uninstall unwanted applications (OneDrive, bloatware)?") {
    
    # --- 1. Terminate Running Processes ---
    $ProcessesToKill = @("OneDrive")
    foreach ($Proc in $ProcessesToKill) {
        if (Get-Process -Name $Proc -ErrorAction SilentlyContinue) {
            Write-Log "Stopping process $Proc..."
            Get-Process -Name $Proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }

    # --- 2. Winget Package Uninstalls ---
    $WingetUninstalls = @(
        "Microsoft.OneDrive"
    )

    foreach ($PkgId in $WingetUninstalls) {
        Write-Log "Uninstalling Winget package: $PkgId..."
        try {
            # Try uninstalling with user scope first, then machine scope, suppressing raw stream errors
            $null = & winget uninstall --id $PkgId --silent --accept-source-agreements --scope user -e 2>&1
            $null = & winget uninstall --id $PkgId --silent --accept-source-agreements --scope machine -e 2>&1
        } catch {
            Write-Host "  [WARN] Winget uninstall for $PkgId encountered an issue or was not found." -ForegroundColor Yellow
        }
    }

    # --- 3. Appx/MSIX Package Removals ---
    $AppxUninstalls = @(
        "*OneDrive*"
    )

    foreach ($AppxName in $AppxUninstalls) {
        Write-Log "Removing Appx package matching: $AppxName..."
        try {
            Get-AppxPackage -AllUsers $AppxName -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  [WARN] Appx removal for $AppxName encountered an issue." -ForegroundColor Yellow
        }
    }

    # --- 4. Native Setup Executable Uninstalls ---
    # OneDrive Native Setup
    $OneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (-not (Test-Path $OneDriveSetup)) {
        $OneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
    }
    if (Test-Path $OneDriveSetup) {
        Write-Log "Running OneDrive native uninstaller..."
        try {
            Start-Process -FilePath $OneDriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        } catch {}
    }

    # --- 5. Restore User Shell Folders Redirection ---
    Write-Log "Checking and restoring User Shell Folders registry paths to local defaults..."
    $RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $FolderMapping = @{
        "Personal" = "%USERPROFILE%\Documents"
        "{f42ee2d3-909f-4907-8270-afc5aed5aec0}" = "%USERPROFILE%\Documents"
        "Desktop" = "%USERPROFILE%\Desktop"
        "{7583693e-3756-4fed-9b17-cf50bcd8847d}" = "%USERPROFILE%\Desktop"
        "My Pictures" = "%USERPROFILE%\Pictures"
        "{0ddd015d-b087-4790-a319-7971965dbd03}" = "%USERPROFILE%\Pictures"
        "My Music" = "%USERPROFILE%\Music"
        "{a0c69a99-21c8-4671-8703-7934162fcf1d}" = "%USERPROFILE%\Music"
        "My Video" = "%USERPROFILE%\Videos"
        "{fdd39ad0-238f-46af-adb4-6c85480369c7}" = "%USERPROFILE%\Videos"
    }

    $NeedExplorerRestart = $false
    foreach ($Key in $FolderMapping.Keys) {
        $DefaultValue = $FolderMapping[$Key]
        try {
            $CurrentValue = Get-ItemPropertyValue -Path $RegistryPath -Name $Key -ErrorAction SilentlyContinue
            if ($CurrentValue -and ($CurrentValue -like "*OneDrive*")) {
                Write-Log "Restoring Shell Folder '$Key' to '$DefaultValue'..."
                
                # Ensure physical destination folder exists
                $ResolvedPath = $DefaultValue.Replace("%USERPROFILE%", $env:USERPROFILE)
                if (-not (Test-Path $ResolvedPath)) {
                    New-Item -ItemType Directory -Path $ResolvedPath -Force | Out-Null
                }
                
                Set-ItemProperty -Path $RegistryPath -Name $Key -Value $DefaultValue -Force
                $NeedExplorerRestart = $true
            }
        } catch {
            Write-Host "  [WARN] Failed to check or restore shell folder '$Key': $_" -ForegroundColor Yellow
        }
    }

    # --- 6. Delete OneDrive Folders from User Directory ---
    Write-Log "Cleaning up OneDrive directories from user profile..."
    $OneDriveDirs = Get-ChildItem -Path $env:USERPROFILE -Directory -Filter "*OneDrive*" -ErrorAction SilentlyContinue
    foreach ($Dir in $OneDriveDirs) {
        Write-Log "Deleting OneDrive directory: $($Dir.FullName)..."
        try {
            # Clear read-only attributes to prevent permission issues
            Get-ChildItem -Path $Dir.FullName -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Attributes -match "ReadOnly") {
                    $_.Attributes = 'Normal'
                }
            }
            Remove-Item -Path $Dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Log "Successfully deleted $($Dir.FullName)."
        } catch {
            Write-Host "  [WARN] Failed to fully delete $($Dir.FullName): $_. You may need to delete it manually after a reboot." -ForegroundColor Yellow
        }
    }

    if ($NeedExplorerRestart) {
        Write-Log "Restarting Windows Explorer to apply folder redirection..."
        try {
            Stop-Process -Name explorer -Force
        } catch {
            Write-Host "  [WARN] Failed to restart Windows Explorer. Please restart manually." -ForegroundColor Yellow
        }
    }

    Write-Log "Uninstalls module completed."
} else {
    Write-Log "Skipping uninstalls."
}
