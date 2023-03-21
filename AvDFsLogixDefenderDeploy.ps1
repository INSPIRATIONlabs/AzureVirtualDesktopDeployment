# Based on the work of Marcel and his article: https://blog.itprocloud.de/Using-FSLogix-file-shares-with-Azure-AD-cloud-identities-in-Azure-Virtual-Desktop-AVD/
# Modified by: Dominic Böttger

param(
    [Parameter(Mandatory=$true)]
    [string]$fileserver,
    [Parameter(Mandatory=$true)]
    [string]$sharename
)

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