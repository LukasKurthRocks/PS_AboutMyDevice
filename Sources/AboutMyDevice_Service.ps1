
#$ProgData = $env:PROGRAMDATA
#$Current_Folder = split-path $MyInvocation.MyCommand.Path
$AboutMyDevice_Folder = "$env:PROGRAMDATA\SD_AboutMyDevice"
$Log_File = "$AboutMyDevice_Folder\GRT_AboutMyDevice.log"

function Write_Log {
	param(
		$Message_Type,
		$Message
	)

	$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
	Add-Content $Log_File "$MyDate - $Message_Type : $Message"
	Write-Host "$MyDate - $Message_Type : $Message"
}

if (!(Test-Path $Log_File)) { New-Item $Log_File -Type File -Force }

while ($true) {
	Add-Content $Log_File ""

	try {
		Import-Module "$AboutMyDevice_Folder\RunasUser"
		Write_Log -Message_Type "SUCCESS" -Message "Successful import of the RunasUser module"
		$RunasUser_Module_imported = $True
	}
	catch {
		Write_Log -Message_Type "ERROR" -Message "Error while importing the RunasUser module"
		$RunasUser_Module_imported = $False
	}

	if ($RunasUser_Module_imported -eq $True) {
		$scriptblock = {
			powershell -ExecutionPolicy ByPass -NoProfile "C:\ProgramData\SD_AboutMyDevice\AboutMyDevice_Systray.ps1"
		}
		try {
			Write_Log -Message_Type "INFO" -Message "Running the current comparison script"
			Invoke-AsCurrentUser -ScriptBlock $scriptblock
			Write_Log -Message_Type "SUCCESS" -Message "Running the comparison script"
		}
		catch {
			Write_Log -Message_Type "ERROR" -Message "Error while running the comparison script"
		}
	}

	Write_Log -Message_Type "INFO" -Message "The process of checking the $AboutMyDevice_Folder program will be paused for 3 hours"
	Add-Content $Log_File ""
	Write-Host ""
	Start-Sleep -Seconds 10
}