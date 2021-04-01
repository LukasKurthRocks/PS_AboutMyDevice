$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$AboutMyDevice_Folder = "$env:PROGRAMDATA\SD_AboutMyDevice"
$Log_File = "$env:SystemRoot\Debug\SD_AboutMyDevice.log"
$ServiceName = "About My Device"
$Service_Description = "A systray tool allowing user to display information about his device, and run some actions"

function Write_Log {
	param(
		$Message_Type,
		$Message
	)

	$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
	Add-Content $Log_File "$MyDate - $Message_Type : $Message"
	Write-Host "$MyDate - $Message_Type : $Message"
}

Add-Content $Log_File ""
if (Test-Path $AboutMyDevice_Folder) { Remove-Item $AboutMyDevice_Folder -Recurse -Force }

try {
	New-Item $AboutMyDevice_Folder -Force -Type Directory
	if (!(Test-Path $Log_File)) { New-Item $Log_File -Type File -Force }
	Write_Log -Message_Type "SUCCESS" -Message "Creating folder: $AboutMyDevice_Folder"
	$Create_Folder_Status = $True
}
catch {
	Write_Log -Message_Type "ERROR" -Message "n error occured while creating folder: $AboutMyDevice_Folder"
	$Create_Folder_Status = $False
}

Add-Content $Log_File ""
if ($Create_Folder_Status -eq $True) {
	try {
		Copy-Item "$Current_Folder\Sources\*" $AboutMyDevice_Folder -Recurse -Force
		$Script:Local_Path_NSSM = "$AboutMyDevice_Folder\nssm.exe"
		Write_Log -Message_Type "SUCCESS" -Message "Sources files have been copied in: $AboutMyDevice_Folder"
		$Files_Copy_Status = $True
	}
	catch {
		Write_Log -Message_Type "ERROR" -Message "An error occured while copying files in: $AboutMyDevice_Folder"
		$Files_Copy_Status = $False
	}
}

Add-Content $Log_File ""
if ($Files_Copy_Status -eq $True) {
	$PathPowerShell = (Get-Command Powershell).Source
	$PS1_To_Run = "$AboutMyDevice_Folder\AboutMyDevice_Service.ps1"
	$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $PS1_To_Run
	try {
		& $Local_Path_NSSM install $ServiceName $PathPowerShell $ServiceArguments
		Start-Sleep -Seconds 5
		Write_Log -Message_Type "SUCCESS" -Message "The service $ServiceName has been successfully created"
		$Create_Service_Status = $True
	}
	catch {
		Write_Log -Message_Type "ERROR" -Message "An issue occured while creating the service: $ServiceName"
		$Create_Service_Status = $False
	}
}

Add-Content $Log_File ""
if ($Create_Service_Status -eq $True) {
	$PathPowerShell = (Get-Command Powershell).Source
	try {
		& $Local_Path_NSSM start $ServiceName
		& $Local_Path_NSSM set $ServiceName description $Service_Description
		Write_Log -Message_Type "SUCCESS" -Message "Starting service $ServiceName"
	}
	catch {
		Write_Log -Message_Type "ERROR" -Message "An issue occured while starting service $ServiceName"
	}
}