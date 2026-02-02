Write-Log "Starting package installation..."

if (Request-Confirmation "Do you want to install your software list?") {
	$Packages = @(
		# --- Core Tools ---
		"Git.Git",
		"CoreyButler.NVMforWindows",
		"OpenJS.NodeJS",
		"Microsoft.PowerShell",
		"Python.Launcher",
		"Python.Python.3.14",
		"Starship.Starship",
        
		# --- Editors ---
		"Neovim.Neovim",
		"Microsoft.VisualStudioCode",
        
		# --- Development ---
		"DBeaver.DBeaver.Community",
		"Docker.DockerDesktop",
		"Postman.Postman",
		"Google.Antigravity",

		# --- CLI Utilities ---
		"Sharkdp.Fd", # fd (faster find)
		"Junegunn.Fzf", # fzf for Windows
		"voidtools.Everything",
		"WinsiderSS.SystemInformer",
		"Microsoft.PowerToys",

		# --- Applications ---
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
			winget install -e --id $Pkg --accept-source-agreements --accept-package-agreements
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