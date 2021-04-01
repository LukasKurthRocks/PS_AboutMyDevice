# ##########################################################################################
# Use this part if you have an external XML for content to collect
# ##########################################################################################

$Current_Folder = Split-Path $MyInvocation.MyCommand.Path

# ##########################################################################################
# Main variables
# ##########################################################################################

$SystemRoot = $env:SystemRoot
$CompName = $env:COMPUTERNAME

$Get_Day_Date = Get-Date -Format "yyyyMMdd"
$Log_File = "$env:temp\Collect_Device_Content_$CompName" + "_$Get_Day_Date.log"
# $Log_File = "$SystemRoot\Debug\Collect_Device_Content_$CompName" + "_$Get_Day_Date.log"
# $Logs_Collect_Folder = "C:\Device_Logs_From" + "_$CompName" #+ "_$Get_Day_Date"
$Logs_Collect_Folder = "$env:temp\Device_Logs_From" + "_$CompName" #+ "_$Get_Day_Date"
$Logs_Collect_Folder_ZIP = "$Logs_Collect_Folder" + ".zip"
$EVTX_files = "$Logs_Collect_Folder\EVTX_Files"
$Reg_Export = "$Logs_Collect_Folder\Export_Reg_Values.csv"
$Logs_Folder = "$Logs_Collect_Folder\All_logs"

$XML_Path = "$Current_Folder\Content_to_collect.xml"
$Content_to_collect_XML = [xml] (Get-Content $XML_Path)
if (!(Test-Path $Logs_Collect_Folder)) { New-Item $Logs_Collect_Folder -Type Directory -Force | Out-Null }
if (!(Test-Path $EVTX_files)) { New-Item $EVTX_files -Type Directory -Force | Out-Null }
if (!(Test-Path $Log_File)) { New-Item $Log_File -Type file -Force | Out-Null }
if (!(Test-Path $Logs_Folder)) { New-Item $Logs_Folder -Type Directory -Force | Out-Null }

# ##########################################################################################
# Main functions
# ##########################################################################################

function Write_Log {
	param(
		$Message_Type,
		$Message
	)

	$MyDate = "[{0:MM/dd/yy}{0:HH:mm:ss}]" -f (Get-Date)
	Add-Content $Log_File  "$MyDate - $Message_Type : $Message"
	# Write-Host "$MyDate - $Message_Type : $Message"
}

function Export_Event_Logs {
	param(
		$Log_To_Export,
		$Log_Output,
		$File_Name
	)

	Write_Log -Message_Type "INFO" -Message "Collecting logs from: $Log_To_Export"
	try {
		WEVTUtil export-log $Log_To_Export "$Log_Output\$File_Name.evtx" | Out-Null
		Write_Log -Message_Type "SUCCESS" -Message "Event log $File_Name.evtx has been successfully exported"
	}
	catch {
		Write_Log -Message_Type "ERROR" -Message "An issue occured while exporting event log $File_Name.evtx"
	}
}

function Export_Logs_Files_Folders {
	param(
		$Log_To_Export,
		$Log_Output
	)

	if (Test-Path $Log_To_Export) {
		$Content_Name = Get-Item $Log_To_Export
		try {
			Copy-Item $Log_To_Export $Log_Output -Recurse -Force
			Write_Log -Message_Type "SUCCESS" -Message "The folder $Content_Name has been successfully copied"
		}
		catch {
			Write_Log -Message_Type "ERROR" -Message "An issue occured while copying the folder $Content_Name"
		}
	}
	else {
		Write_Log -Message_Type "ERROR" -Message "The following path does not exist: $Log_To_Export"
	}
}

function Export_Registry_Values {
	param(
		$Reg_Path,
		$Reg_Specific_Value,
		$Output_Path
	)

	if (Test-Path "Registry::$Reg_Path") {
		$Reg_Array = @()
		$Get_Reg_Values = Get-ItemProperty -Path "Registry::$Reg_Path"
		if ($Reg_Specific_Value) {
			$List_Values = $Get_Reg_Values.$Reg_Specific_Value
			$Get_Reg_Values_Array = New-Object PSObject
			$Get_Reg_Values_Array = $Get_Reg_Values_Array | Add-Member NoteProperty Name $Reg_Specific_Value -passthru
			$Get_Reg_Values_Array = $Get_Reg_Values_Array | Add-Member NoteProperty Value $List_Values -passthru
			$Get_Reg_Values_Array = $Get_Reg_Values_Array | Add-Member NoteProperty Reg_Path $Reg_Path -passthru
		}
		else {
			$List_Values = $Get_Reg_Values.psobject.properties | Select-Object name, value | Where-Object { ($_.name -ne "PSPath" -and $_.name -ne "PSParentPath" -and $_.name -ne "PSChildName" -and $_.name -ne "PSProvider") }
			$Get_Reg_Values_Array = New-Object PSObject
			$Get_Reg_Values_Array = $List_Values
			$Get_Reg_Values_Array = $Get_Reg_Values_Array | Add-Member NoteProperty Reg_Path $Reg_Path -passthru
		}

		$Reg_Array += $Get_Reg_Values_Array

		if (!(Test-Path $Output_Path)) {
			try {
				$Reg_Array | export-csv $Output_Path  -notype
				Write_Log -Message_Type "SUCCESS" -Message "Registry values from $Reg_Path have been successfully exported"
			}
			catch {
				Write_Log -Message_Type "ERROR" -Message "An issue occured while exporting registry values from $Reg_Path"
			}
		}
		else {
			try {
				$Reg_Array | export-csv -Append $Output_Path  -notype
				Write_Log -Message_Type "SUCCESS" -Message "Registry values from $Reg_Path have been successfully exported"
			}
			catch {
				Write_Log -Message_Type "ERROR" -Message "An issue occured while exporting registry values from $Reg_Path"
			}
		}
	}
	else {
		Write_Log -Message_Type "ERROR" -Message "The following REG path does not exist: $Reg_Path"
	}
}

# ##########################################################################################
# Main code
# ##########################################################################################

Write_Log -Message_Type "INFO" -Message "Starting collecting Intune logs on $CompName"

Add-Content $Log_File ""
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
Write_Log -Message_Type "INFO" -Message "Step 1 - Collecting event logs"
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
$Events_To_Check = $Content_to_collect_XML.Content_to_collect.Event_Logs.Event_Log
foreach ($Event in $Events_To_Check) {
	$Event_Name = $Event.Event_Name
	$Event_Path = $Event.Event_Path
	Export_Event_Logs -Log_To_Export $Event_Path -Log_Output $EVTX_files -File_Name $Event_Name
}

Add-Content $Log_File ""
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
Write_Log -Message_Type "INFO" -Message "Step 2 - Copying files and folders"
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
$Folder_To_Check = $Content_to_collect_XML.Content_to_collect.Folders.Folder_Path
foreach ($Explorer_Content in $Folder_To_Check) {
	Export_Logs_Files_Folders -Log_To_Export $Explorer_Content -Log_Output $Logs_Folder
}

Add-Content $Log_File ""
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
Write_Log -Message_Type "INFO" -Message "Step 3 - Collecting registry keys"
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
$Reg_Keys_To_Check = $Content_to_collect_XML.Content_to_collect.Reg_Keys.Reg_Key
foreach ($Reg in $Reg_Keys_To_Check) {
	$Get_Reg_Path = $Reg.Reg_Path
	$Get_Reg_Specific_Value = $Reg.Reg_Specific_Value
	if ($null -ne $Get_Reg_Specific_Value) {
		Export_Registry_Values -Reg_Path $Get_Reg_Path -Reg_Specific_Value $Get_Reg_Specific_Value -Output_Path $Reg_Export
	}
	else {
		Export_Registry_Values -Reg_Path $Get_Reg_Path -Output_Path $Reg_Export
	}
}

Add-Content $Log_File ""
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
Write_Log -Message_Type "INFO" -Message "Step 4 - Creating the ZIP with logs"
Add-Content $Log_File "---------------------------------------------------------------------------------------------------------"
try {
	Add-Type -assembly "system.io.compression.filesystem"
	[io.compression.zipfile]::CreateFromDirectory($Logs_Collect_Folder, $Logs_Collect_Folder_ZIP)
	Write_Log -Message_Type "SUCCESS" -Message "The ZIP file has been successfully created"
	Write_Log -Message_Type "INFO" -Message "The ZIP is located in :$Logs_Collect_Folder_ZIP"
}
catch {
	Write_Log -Message_Type "ERROR" -Message "An issue occured while creating the ZIP file"
}
 