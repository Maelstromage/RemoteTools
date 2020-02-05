$HKEY = 2147483651
$computer = "usblnd0150"


$explorer = Get-WmiObject -ComputerName $Computer -Class win32_process | where {$_.name -eq "explorer.exe"}
$sid = ($explorer.GetOwnerSid()).sid
$user  = $explorer.GetOwner()

$strKeyPath = "$sid\network"

$objReg = [WMIClass]"\\$computer\root\default:StdRegProv"

$arrSubKeys = $objReg.EnumKey($HKEY, $strKeyPath)
foreach ($subKey in ($arrSubKeys.sNames))
{
    write-output "$subKey `t $($objReg.GetExpandedStringValue($HKEY, "$strKeyPath\$subkey", "RemotePath").svalue)"

}
