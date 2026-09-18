param(
	[Parameter(Mandatory=$true)]
	[string]$SamAccountName
)

Disable-ADAccount -Identity $SamAccountName

$groups = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Where-Object { $_.Name -ne "Domain Users"}

foreach ($group in $groups){
	Remove-ADGroupMember -Identity $group.Name -Members $SamAccountName -Confirm:$false
	Write-Output "Removed $SamAccountName from $($group.Name)"
}

Write-Output "$SamAccountName has been disabled and removed from all groups."