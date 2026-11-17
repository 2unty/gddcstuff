Write-Host "-------- Normal Users --------"

Get-Content -Path "C:\Users\Administrator\gddcstuff-main\normal.txt" | ForEach-Object {
	$user = ("$_" -split "::")[0] 
	$pass = ("$_" -split "::")[1] | ConvertTo-SecureString -AsPlainText -Force
	Set-ADAccountPassword -Identity $user -Reset -NewPassword $pass
	Enable-ADAccount -Identity $user
	
}
