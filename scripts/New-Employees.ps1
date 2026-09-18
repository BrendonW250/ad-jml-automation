$employees = Import-Csv -Path "C:\new-hires.csv"

foreach ($employee in $employees){
	$name = $employee.Name
	$department = $employee.Department
	$samAccountName = ($name -replace " ", "").ToLower()

	New-ADUser -Name $name `
		-SamAccountName $samAccountName `
		-Path "OU=$department,DC=corplab,DC=local" `
		-AccountPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Enabled $true

	Add-ADGroupMember -Identity "GRP-$department-Users" -Members $samAccountName

	Write-Output "Created $name in $department"
}