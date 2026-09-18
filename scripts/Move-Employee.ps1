param(
	[Parameter(Mandatory=$true)]
	[string]$SamAccountName,

	[Parameter(Mandatory=$true)]
	[string]$NewDepartment
)

$oldGroups = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Where-Object { $_.Name -ne "Domain Users" }

foreach ($group in $oldGroups) {
	Remove-ADGroupMember -Identity $group.Name -Members $SamAccountName -Confirm:$false -ErrorAction Stop
	Write-Output "Removed $SamAccountName from $($group.Name)"
}

$user = Get-ADUser -Identity $SamAccountName
Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=$NewDepartment,DC=corplab,DC=local"

Add-ADGroupMember -Identity "GRP-$NewDepartment-Users" -Members $SamAccountName 

Write-Output "$SamAccountName moved to $NewDepartment and access updated."