$AboutMyDevice_Folder = $env:ProgramData + "\SD_AboutMyDevice"
$Log_File = "$env:SystemRoot\Debug\GRT_AboutMyDevice.log"
$ServiceName = "About My Device"

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

$OD_Process_Status = (gwmi win32_process | Where-Object { $_.commandline -like "*AboutMydevice_Systray*" })
$OD_Process_Status2 = get-process | Where-Object { $_.MainWindowTitle -like "*About my device*" }
if ($null -ne $OD_Process_Status) {
	$OD_Process_Status.Terminate()
}

if ($null -ne $OD_Process_Status2) {
	$OD_Process_Status2 | Stop-Process -Force
}

$Script:Local_Path_NSSM = "$AboutMyDevice_Folder\nssm.exe"
$Local_Path_NSSM = "$AboutMyDevice_Folder\nssm.exe"
Get-Service $ServiceName | Stop-Service
& $Local_Path_NSSM remove $ServiceName confirm
if (Test-Path $AboutMyDevice_Folder) { Remove-Item $AboutMyDevice_Folder -Recurse -Force }