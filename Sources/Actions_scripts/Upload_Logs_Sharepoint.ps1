# $Get_Sharepoint_Content = [xml](get-content "$current_folder\Config\Sharepoint.xml")
# $Get_Sharepoint_Content = [xml](get-content "..\Config\Sharepoint.xml")
# cd..
# $Get_Sharepoint_Content = [xml](get-content ".\Config\Sharepoint.xml")
$Get_Sharepoint_Content = [xml](Get-Content "D:\GRT_AboutMyComputer\SD\Sources\Config\Sharepoint.xml")
$Sharepoint_App_ID = $Get_Sharepoint_Content.Infos.App_ID
$Sharepoint_App_Secret = $Get_Sharepoint_Content.Infos.App_Secret
$Sharepoint_Folder = $Get_Sharepoint_Content.Infos.Folder
$Sharepoint_Site_URL = $Get_Sharepoint_Content.Infos.Site_URL

$Logs_Collect_Folder = "$env:temp\Device_Logs_From" + "_$env:COMPUTERNAME"
$Logs_Collect_Folder_ZIP = "$Logs_Collect_Folder" + ".zip"

$Is_Nuget_Installed = $False 
if (!(Get-PackageProvider | Where-Object { $_.Name -eq "Nuget" })) { 
	Write_Log -Message_Type "SUCCESS" -Message "The package Nuget is not installed" 
	try {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Confirm:$False | Out-Null 
		$Is_Nuget_Installed = $True 
	}
	catch {
		break
	}
}
else {
	$Is_Nuget_Installed = $True 
}

if ($Is_Nuget_Installed -eq $True) {
	$Script:PnP_Module_Status = $False
	$Module_Name = "PnP.PowerShell"
	if (!(Get-InstalledModule $Module_Name -ErrorAction SilentlyContinue)) { 
		Install-Module $Module_Name -Force -Confirm:$False -ErrorAction SilentlyContinue | Out-Null 
		#$Module_Version = (Get-Module $Module_Name -listavailable).version
		$PnP_Module_Status = $True 
	}
	else { 
		Import-Module $Module_Name -Force -ErrorAction SilentlyContinue 
		$PnP_Module_Status = $True 
	}
}

if ($PnP_Module_Status -eq $True) { 
	try {
		Connect-PnPOnline -Url $Sharepoint_Site_URL -ClientID $Sharepoint_App_ID -ClientSecret $Sharepoint_App_Secret
		$Sharepoint_Status = "OK"
	}
	catch {
		$Sharepoint_Status = "KO"
	}

	if ($Sharepoint_Status -eq "OK") {
		Add-PnPFile -Path $Logs_Collect_Folder_ZIP -Folder $Sharepoint_Folder #| Out-Null
	}
}