#need to be run with a user account that has admin rights to the computers and print servers.
$computers = (Get-ADComputer -Filter * -SearchBase "OU=USBLN,OU=Computers,OU=AMER,OU=SSC,DC=ad,DC=global").name

$savepath = "C:\test\testmapdata"
$HKEY = 2147483651

$mappeddata = @()


foreach ($computer in $computers){
    if(Test-Connection $computer -Quiet -Count 1){
        Write-Output "`r`nComputer: $computer"
        $explorer = Get-WmiObject -ComputerName $Computer -Class win32_process | where {$_.name -eq "explorer.exe"}
        if($explorer -ne $null){
            $sids = ($explorer.GetOwnerSid()).sid
            $users  = $explorer.GetOwner()
            $usrcount = 0
            foreach($user in $users){
                if($sids -is [array]){$sid = $sids[$usrcount]}else{$sid = $sids}
                $usrcount++
                $drivesPath = "$sid\network"
                $printersPath = "$sid\Printers\Connections"
                $objReg = [WMIClass]"\\$computer\root\default:StdRegProv"
                $drivesarrSubKeys = $objReg.EnumKey($HKEY, $drivesPath)
                $printersarrSubKeys = $objReg.EnumKey($HKEY, $printersPath)
                $data = New-Object psobject
                $data | Add-Member -NotePropertyName "Computer" -NotePropertyValue $computer
                $data | Add-Member -NotePropertyName "User" -NotePropertyValue $user.user
                Write-Output "User: $($user.user)"
                foreach ($subKey in ($drivesarrSubKeys.sNames))
                {
                    $data | Add-Member -NotePropertyName $subKey -NotePropertyValue $objReg.GetExpandedStringValue($HKEY, "$drivesPath\$subkey", "RemotePath").svalue
                    write-output "$subKey `t $($objReg.GetExpandedStringValue($HKEY, "$drivesPath\$subkey", "RemotePath").svalue)"
                }
                $count = 0
                foreach ($subKey in ($printersarrSubKeys.sNames))
                {
                    $server = $subKey.split(',')[2]
                    $sharename = $subKey.split(',')[3]
                    if(Test-Connection $server -Quiet -Count 1){
                        $printer = get-printer -ComputerName $server | where {$_.name -eq $sharename}
                        if($printer -ne $null){
                            $count++
                            if($printer -is [array]){$printer = $printer[0]}#uses the first printer if multiple printers are found.
                            $data | Add-Member -NotePropertyName "Printer$count" -NotePropertyValue "\\$($printer.ComputerName)\$($printer.ShareName)"
                            Write-Output "\\$($printer.ComputerName)\$($printer.ShareName)"
                        }else{Write-host "Printer $sharename does not exist on $server" -ForegroundColor Red}
                    }else{Write-host "Could not connect to $server When searching for printer $sharename" -ForegroundColor Red}
                }
                $mappeddata += $data
            }
        }else{Write-host "Explorer.exe is not running on $computer" -ForegroundColor Red}
    }else{Write-host "Could not connect to $computer" -ForegroundColor Red}
}
$mappeddata | ConvertTo-Json |  % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | Add-Content -Path "$savepath.json"
