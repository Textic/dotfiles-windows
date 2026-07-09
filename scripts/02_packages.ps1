Write-Log "Starting package installation..."

if (Request-Confirmation "Do you want to upgrade ALL currently installed applications first?") {
    Write-Log "Upgrading installed packages..."
    try {
        $UpgradeArgs = @("upgrade", "--all", "--include-unknown", "--accept-source-agreements", "--accept-package-agreements")
        if (-not $Global:Unattended) {
            $UpgradeArgs += "--silent"
        }
        winget $UpgradeArgs
        Write-Log "System upgrade finished."
    } catch {
        Write-Host "  [WARN] Some upgrades might have failed or required interaction." -ForegroundColor Yellow
    }
}

if (Request-Confirmation "Do you want to install the package list?") {
	$Packages = @(
		# --- Core Tools ---
		"Git.Git",
		"Microsoft.PowerShell",
		"Starship.Starship",
		"WinsiderSS.SystemInformer",
        
		# --- Editors ---
		"Neovim.Neovim",
		"Microsoft.VisualStudioCode",
        
		# --- Development ---
		"DBeaver.DBeaver.Community",
		"Docker.DockerDesktop",
		"Postman.Postman",
		
		# --- CLI Utilities ---
		"Ngrok.Ngrok",
		
		# --- Applications ---
		"Microsoft.PowerToys",
		"voidtools.Everything",
		"RARLab.WinRAR",
		"Google.GoogleDrive",
		"Elgato.StreamDeck",
		"Google.Chrome",
		"Valve.Steam",
		"Discord.Discord"
	)

	Write-Log "Found $( $Packages.Count ) packages to process."

	foreach ($Pkg in $Packages) {
		Write-Log "Processing $Pkg..."
		try {
			# Check if installed (simple check, winget handles updates too)
			# --accept-source-agreements: Auto-accept license
			# --accept-package-agreements: Auto-accept package license
			$InstallArgs = @("install", "-e", "--id", $Pkg, "--accept-source-agreements", "--accept-package-agreements")
			if (-not $Global:Unattended) {
				$InstallArgs += "--silent"
			}
			winget $InstallArgs
		}
		catch {
			Write-Host "  [WARN] Issue installing $Pkg (might be already installed or network error)." -ForegroundColor Red
		}
	}
    
	Write-Log "Package installation routine finished."
}
else {
	Write-Log "Skipping packages."
}