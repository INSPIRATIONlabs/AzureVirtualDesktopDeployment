param(
    [string]$Authkey
)

if (-not $Authkey) {
    Write-Error "Authkey parameter is missing."
    Exit 1
}

# Download the latest Tailscale client MSI
$TailscaleUrl = 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi'
$TailscalePath = "$env:TEMP\tailscale.msi"
Invoke-WebRequest -Uri $TailscaleUrl -OutFile $TailscalePath

# Install the Tailscale client using the MSI, allow incoming connections, and start Tailscale after installation
$InstallerArgs = @(
    "/i",
    "`"$TailscalePath`"",
    "/quiet",
    "/norestart",
    "TS_ADMINCONSOLE=hide",
    "TS_ALLOWINCOMINGCONNECTIONS=always",
    "TS_KEYEXPIRATIONNOTICE=24h",
    "TS_NETWORKDEVICES=hide",
    "TS_TESTMENU=hide",
    "TS_UPDATEMENU=hide",
    "TS_UNATTENDEDMODE=always"
)
Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallerArgs -Wait

# Set the Tailscale authkey and start Tailscale
& "C:\Program Files\Tailscale\tailscale.exe" up --authkey=$Authkey --accept-routes --unattended

# Clean up the downloaded MSI
Remove-Item $TailscalePath
