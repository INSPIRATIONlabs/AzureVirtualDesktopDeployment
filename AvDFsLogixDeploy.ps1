# Script to install fslogix on a Windows system and configure Microsoft Defender.
# Based on the work of Marcel and his article: https://blog.itprocloud.de/Using-FSLogix-file-shares-with-Azure-AD-cloud-identities-in-Azure-Virtual-Desktop-AVD/
# Modified by: Dominic Böttger
#
# Add Parameters for the script all parameters are mandatory
# - fileServer: The name of the file server
# - profileShare: The connection string to the profile share
# - user: The user name to access the file server
# - secret: The password to access the file server
param(
    [Parameter(Mandatory=$true)]
    [string]$fileserver,
    [Parameter(Mandatory=$true)]
    [string]$profileshare,
    [Parameter(Mandatory=$true)]
    [string]$user,
    [Parameter(Mandatory=$true)]
    [string]$secret,
    [Parameter(Mandatory=$true)]
    [string]$sharename
)

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
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "IncludeTeams" -Value 1 -force
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
Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member "defaultuser100000"
Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "defaultuser100000"

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
    Add-MpPreference -ExclusionPath $item}
Foreach($item in $processlist){
    Add-MpPreference -ExclusionProcess $item}

If ($Cloudcache){
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Cache\*.VHDX"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHD"
    Add-MpPreference -ExclusionPath "%ProgramData%\FSLogix\Proxy\*.VHDX"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Cache\*.VHD"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Cache\*.VHDX"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Proxy\*.VHD"
    Add-MpPreference -ExclusionPath "D:\FSLogix\Proxy\*.VHDX"}

shutdown -r -t 0
