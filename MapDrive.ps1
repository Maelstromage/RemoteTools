#fill in computer driveLetter and DriveLocation
#Please have user log off and log on after complete
$computer = "Computer"
$driveLetter = "L"
$driveLocation = "\\server\share"
if(Test-Connection $computer -Quiet -Count 1){
    Write-Output "`r`nComputer: $computer"
    $explorer = Get-WmiObject -ComputerName $Computer -Class win32_process | where {$_.name -eq "explorer.exe"}
    if($explorer -ne $null){
        $sids = ($explorer.GetOwnerSid()).sid
        $users  = $explorer.GetOwner()
        $usrcount = 0
        foreach($user in $users){
            $yn = read-host "Do you want to map $driveLetter at $driveLocation for user $($user.user) (Y/N)? "
            if($yn -eq "Y"){
                if($sids -is [array]){$sid = $sids[$usrcount]}else{$sid = $sids}
                $usrcount++
                Invoke-Command -ComputerName $computer -ArgumentList $driveLetter, $driveLocation, $sid -ScriptBlock {
                    param ($driveLetter,$driveLocation,$sid)
                    $regPath = "HKU:\$sid\Network\$driveLetter"
                    if(!(Test-Path "HKU:\")){ New-PSDrive HKU Registry HKEY_USERS }
                    if(Test-Path $regPath){Write-Host "$driveLetter is already being used"}else{
                        New-Item $regPath -Force
                        New-ItemProperty -Path $regPath -PropertyType DWORD -Name "ConnectFlags" -Value 0
                        New-ItemProperty -Path $regPath -PropertyType DWORD -Name "ConnectionType" -Value 1
                        New-ItemProperty -Path $regPath -PropertyType DWORD -Name "DeferFlags" -Value 4
                        New-ItemProperty -Path $regPath -PropertyType String -Name "ProviderName" -Value "Microsoft Windows Network"
                        New-ItemProperty -Path $regPath -PropertyType DWORD -Name "ProviderType" -Value 131072
                        New-ItemProperty -Path $regPath -PropertyType String -Name "RemotePath" -Value $driveLocation
                        New-ItemProperty -Path $regPath -PropertyType DWORD -Name "UserName" -Value 0
                    }
                }
            }
        }
    }else{Write-host "Explorer.exe is not running on $computer" -ForegroundColor Red}
}else{Write-host "Could not connect to $computer" -ForegroundColor Red}
Write-host "Please have user log off and log on"
read-host "Press Enter to Continue"
