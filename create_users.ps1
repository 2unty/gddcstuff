param (
	[Parameter(Mandatory=$true)][string]$evilPath, [Parameter(Mandatory=$true)][string]$normalPath
)

Write-Host "-------- Evil Users --------"

Get-Content -Path "$evilPath" | ForEach-Object {
	$user = ("$_" -split "::")[0] 
	$pass = ("$_" -split "::")[1] | ConvertTo-SecureString -AsPlainText -Force
	$exists = Get-ADUser -Filter {Name -eq $user} -ErrorAction SilentlyContinue
	if(-not $exists){
		Write-Host "[+] Creating user: $user with password: $pass"
		New-ADUser -Name $user -SamAccountName $user -AccountPassword $pass -Enabled $true -ChangePasswordAtLogon $false
		#Write-Host "New-ADUser -Name $user -SamAccountName $user -AccountPassword $pass -Enabled $true -ChangePasswordAtLogon $false"
	}
	Write-Host "[+] Adding $user to Domain Admin and Remote Desktop User groups"
	Add-ADGroupMember -Identity "Domain Admins" -Members $user
	Add-ADGroupMember -Identity "Remote Desktop Users" -Members $user
	#Write-Host "Add-ADGroupMember -Identity `"Domain Admins`" -Members $user"
	#Write-Host "Add-ADGroupMember -Identity `"Remote Desktop Users`" -Members $user"
}

Write-Host "-------- Normal Users --------"

Get-Content -Path "$normalPath" | ForEach-Object {
	$user = ("$_" -split "::")[0] 
	$pass = ("$_" -split "::")[1] | ConvertTo-SecureString -AsPlainText -Force
	$exists = Get-ADUser -Filter {Name -eq $user} -ErrorAction SilentlyContinue
	if(-not $exists){
		Write-Host "[+] Creating user: $user with password: $pass"
		New-ADUser -Name $user -SamAccountName $user -AccountPassword $pass -Enabled $true -ChangePasswordAtLogon $false
		#Write-Host "New-ADUser -Name $user -SamAccountName $user -AccountPassword $pass -Enabled $true -ChangePasswordAtLogon $false"
	}
	Write-Host "[+] Adding $user to Domain Users group"
	Add-ADGroupMember -Identity "Domain Users" -Members $user
	#Write-Host "Add-ADGroupMember -Identity `"Domain Users`" -Members $user"
}
