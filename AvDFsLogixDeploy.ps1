
New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\FSLogix" -Name "Profiles" -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "AccessNetworkAsComputerObject" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "CCDLocations" -Value $profileShare -force
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
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "CCDLocations" -Value $profileShare -force
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


# Store credentials to access the storage account
cmdkey.exe /add:$fileServer /user:$($user) /pass:$($secret)
# Disable Windows Defender Credential Guard (only needed for Windows 11 22H2)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LsaCfgFlags" -Value 0 -force

Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member "azure"
Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member "azure"

write-host "The script has finished."
