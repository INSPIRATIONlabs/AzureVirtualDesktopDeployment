# A script which installs multiple components on a Windows machine
# Current installable components
# - FSLogix
# - Tailscale (optional)
# 
# Parameters for FslLogix installation are:
# - fileServer: The name of the file server
# - profileShare: The connection string to the profile share
# - user: The user name to access the file server
# - secret: The password to access the file server
#
# Parameters for Tailscale installation are:
# - tailscaleKey: The key to access the Tailscale network
# 
# The tailscale installation is optional. If the tailscaleKey parameter is not provided, the installation will be skipped.
#
param(
    [Parameter(Mandatory=$true)]
    [string]$fileServer,
    [Parameter(Mandatory=$true)]
    [string]$profileShare,
    [Parameter(Mandatory=$true)]
    [string]$user,
    [Parameter(Mandatory=$true)]
    [string]$secret,
    [Parameter(Mandatory=$true)]
    [string]$sharename,
    [Parameter(Mandatory=$false)]
    [string]$fsLogixPath = "D:\FSLogix",
    [Parameter(Mandatory=$false)]
    [string]$tailscaleAuthkey
)

# check all mandatory parameters
if (-not $fileServer) {
    Write-Error "fileServer parameter is missing."
    Exit 1
}

if (-not $profileShare) {
    Write-Error "profileShare parameter is missing."
    Exit 1
}

if (-not $user) {
    Write-Error "user parameter is missing."
    Exit 1
}

if (-not $secret -and $secret.Length -lt 2) {
    Write-Error "secret parameter is missing."
    Exit 1
}

# Install FSLogix
Write-Host "Installing FSLogix"

New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\FSLogix" -Name "Profiles" -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "AccessNetworkAsComputerObject" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "CCDLocations" -Value $profileshare -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "HealthyProvidersRequiredForRegister" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "KeepLocalDir" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "SizeInMBs" -Value 40000 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VolumeType" -Value "VHDX" -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "PreventLoginWithFailure" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "PreventLoginWithTempProfile" -Value 1 -force

New-Item -Path "HKLM:\SOFTWARE\Policies" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\Policies\FSLogix" -Name "ODFC" -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "AccessNetworkAsComputerObject" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "CCDLocations" -Value $profileshare -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "Enabled" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "HealthyProvidersRequiredForRegister" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "IncludeOfficeActivation" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "IncludeOutlook" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "IncludeOutlookPersonalization" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "PreventLoginWithFailure" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "VolumeType" -Value "VHDX" -force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\frxccds\Parameters" -Name "ProxyDirectory" -Value "D:\FSLogix\Proxy" -force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\frxccds\Parameters" -Name "WriteCacheDirectory" -Value  "D:\FSLogix\Cache" -force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\frxccd\Parameters" -Name "ProxyDirectory" -Value "D:\FSLogix\Proxy" -force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\frxccd\Parameters" -Name "WriteCacheDirectory" -Value "D:\FSLogix\Cache" -force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\frxccd\Parameters" -Name "CacheDirectory" -Value  "D:\FSLogix\Cache" -force

# Disable Windows Defender Credential Guard (only needed for Windows 11 22H2)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LsaCfgFlags" -Value 0 -force

Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member "azure"
Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "azure"

# Store credentials to access the storage account
cmdkey.exe /add:`"$fileserver`" /user:`"$($user)`" /pass:`"$($secret)`"

# Defender Exclusions for FSLogix
$Cloudcache = $true # Set for true if using cloud cache

$filelist = `
"%ProgramFiles%\FSLogix\Apps\frxdrv.sys", `
"%ProgramFiles%\FSLogix\Apps\frxdrvvt.sys", `
"%ProgramFiles%\FSLogix\Apps\frxccd.sys", `
"%TEMP%\*.VHD", `
"%TEMP%\*.VHDX", `
"%Windir%\TEMP\*.VHD", `
"%Windir%\TEMP\*.VHDX", `
"\\$fileserver\$sharename\*.VHD", `
"\\$fileserver\$sharename\*.VHDX"

$processlist = `
"%ProgramFiles%\FSLogix\Apps\frxccd.exe", `
"%ProgramFiles%\FSLogix\Apps\frxccds.exe", `
"%ProgramFiles%\FSLogix\Apps\frxsvc.exe"

Foreach($item in $filelist){
    Add-MpPreference -ExclusionPath $item
}

Foreach($item in $processlist){
    Add-MpPreference -ExclusionProcess $item
}

If ($Cloudcache){
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHDX"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHDX"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Cache\*.VHD"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Cache\*.VHDX"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Proxy\*.VHD"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Proxy\*.VHDX"
}
Write-Host "FSLogix Exclusions added"

# check if the tailscaleAuthkey is set and if so, install tailscale
if( ($tailscaleAuthkey -ne $null) -and ($tailscaleAuthkey -ne "" )) {
    # check if tailscale is installed by checkig the file path C:\Program Files\Tailscale\tailscale.exe
    $tailscaleInstalled = Test-Path -Path "C:\Program Files\Tailscale\tailscale.exe"
    Write-Host "Downloading Tailscale..."
    # Download the latest Tailscale client MSI
    $TailscaleUrl = 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi'
    $TailscalePath = "$env:TEMP\tailscale.msi"
    Invoke-WebRequest -Uri $TailscaleUrl -OutFile $TailscalePath

    Write-Host "Installing Tailscale..."
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
    Write-Host "Excecuting: msiexec.exe for tailscale"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallerArgs -Wait
    Write-Host "Tailscale installed"
    if ($tailscaleInstalled -ne $null) {
        Write-Host "Tailscale already installed, shutdown"
        & "C:\Program Files\Tailscale\tailscale.exe" down
    }
    # Set the Tailscale authkey and start Tailscale
    & "C:\Program Files\Tailscale\tailscale.exe" up --authkey=`"$tailscaleAuthkey`" --accept-routes --unattended
    Write-Host "Tailscale started"
    # Clean up the downloaded MSI
    Remove-Item $TailscalePath
}

Write-Host "Restarting..."
# Restart to finish the installation
shutdown -r -t 0