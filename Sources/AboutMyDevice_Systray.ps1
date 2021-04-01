
$Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null
[System.Reflection.Assembly]::LoadFrom("$Current_Folder\assembly\MahApps.Metro.dll") | Out-Null

$Log_File = "$env:TEMP\about_this_comp.log"

function Write_Log {
	param(
		$Message_Type,
		$Message
	)
 
	$MyDate = "[{0:MM/dd/yy}{0:HH:mm:ss}]" -f (Get-Date)
	Add-Content $Log_File "$MyDate - $Message_Type : $Message" 
	Write-Host "$MyDate - $Message_Type : $Message" 
}
 
if (!(Test-Path $Log_File)) { new-item $Log_File -Type File -force }
$Global:Current_Folder = split-path $MyInvocation.MyCommand.Path

#$AboutMyDevice_Folder = "$env:ProgramData\SD_AboutMyDevice" # Unused
$Systray_Pictures = "$Current_Folder\menu_pictures"

# Create object for the systray 
$Systray_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
# Text displayed when you pass the mouse over the systray icon
$Systray_Tool_Icon.Text = "About My Device"

# Systray icon
$Systray_Tool_Icon.Icon = "$Systray_Pictures\help2.ico"
$Systray_Tool_Icon.Visible = $true

$Get_Support_Infos_Content = [xml](get-content "$current_folder\Config\Main_Config.xml")
#$Main_Language = $Get_Support_Infos_Content.Config.Main_Language
$Display_Send_Logs = $Get_Support_Infos_Content.Config.Display_Send_Logs
$Display_Quick_Assist = $Get_Support_Infos_Content.Config.Display_Quick_Assist
$Display_Open_CompanyPortal = $Get_Support_Infos_Content.Config.Display_Open_CompanyPortal
$Display_Sync = $Get_Support_Infos_Content.Config.Display_Sync
$CompanyPortal_SoftwareCenter_Preference = $Get_Support_Infos_Content.Config.CompanyPortal_SoftwareCenter_Preference
$Send_Logs_Method = $Get_Support_Infos_Content.Config.Send_Logs_Method
$Support_Mail = $Get_Support_Infos_Content.Config.Support_Mail

$contextmenu = New-Object System.Windows.Forms.ContextMenuStrip

$Run_Tool = $contextmenu.Items.Add("Display info about my device");
$Run_Tool_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\help.png")
$Run_Tool.Image = $Run_Tool_Img

if ($Display_Quick_Assist -eq "True") {
	$Run_Quick_Assist = $contextmenu.Items.Add("Open Quick Assist");
	$Run_Quick_Assist_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\quick_assist.png")
	$Run_Quick_Assist.Image = $Run_Quick_Assist_Img
 
	$Run_Quick_Assist.add_Click(
		{
			& "$env:SystemRoot\system32\quickassist.exe"
		}
	)
}

$CompanyPortal_SoftwareCenter_Preference = $Get_Support_Infos_Content.Config.CompanyPortal_SoftwareCenter_Preference

if ($Display_Open_CompanyPortal -eq "True") {
	if ($CompanyPortal_SoftwareCenter_Preference -eq "CompanyPortal") {
		$Run_Portal = $contextmenu.Items.Add("Open Company Portal");
		$Run_Portal_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\portal.png")
		$Run_Portal.Image = $Run_Portal_Img 
 
		$Run_Portal.add_Click(
			{
				$Get_Appli_Name = (Get-AppxPackage -name Microsoft.CompanyPortal).PackageFamilyName
				explorer.exe shell:appsFolder\$Get_Appli_Name!App
			}
		)
	}
	elseif ($CompanyPortal_SoftwareCenter_Preference -eq "SoftwareCenter") {
		$Run_Portal = $contextmenu.Items.Add("Open Software Center");
		$Run_Portal_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\portal.png")
		$Run_Portal.Image = $Run_Portal_Img 
		$Run_Portal.add_Click(
			{
				$Software_Center_Path = "C:\WINDOWS\CCM\ClientUX\SCClient.exe"
				if (Test-Path $Software_Center_Path) {
					Start-Process $Software_Center_Path
				}
			}
		)
	}
}

if ($Display_Sync -eq "True") {
	$Run_Sync_Device = $contextmenu.Items.Add("Sync my device");
	$Run_Sync_Device_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\sync2.png")
	$Run_Sync_Device.Image = $Run_Sync_Device_Img
 
	$Run_Sync_Device.add_Click(
		{
			$Check_Intune_Service = Get-Service intunemanagementextension -ErrorAction SilentlyContinue
			if ($Check_Intune_Service -ne $null) {
				$Shell = New-Object -ComObject Shell.Application
				$Shell.open("intunemanagementextension://syncapp")
			}
			
			if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
				$Get_MECM_Client_Version = (Get-CimInstance -Namespace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue).ClientVersion
			}
			else {
				$Get_MECM_Client_Version = (Get-WMIObject -Namespace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue).ClientVersion
			}
			
			if ($Get_MECM_Client_Version -ne $null) {
				$Client_Actions = @("8EF4D77C", "3A88A2F3")
				$Config_Manager_Object = New-Object -ComObject CPApplet.CPAppletMgr
				foreach ($Action in $Client_Actions) {
					$action_To_Run = $Config_Manager_Object.GetClientActions() | Where-Object { ($_.ActionID -like "*$Action*") }
					$action_To_Run.PerformAction()
				}
			}
		}
	)
}

if ($Display_Send_Logs -eq "True") {
	$Menu_Logs = $contextmenu.Items.Add("Send device logs to support team");
	$Menu_Logs_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\log.png")
	$Menu_Logs.Image = $Menu_Logs_Img
 
	$Menu_Logs.Add_Click(
		{
			if ($Send_Logs_Method -eq "Sharepoint") {
				$Get_Sharepoint_Content = [xml](get-content "$current_folder\Config\Sharepoint.xml")
				$Sharepoint_Folder = $Get_Sharepoint_Content.Infos.Folder
				$Sharepoint_App_ID = $Get_Sharepoint_Content.Infos.App_ID
				$Sharepoint_App_Secret = $Get_Sharepoint_Content.Infos.App_Secret
				$Sharepoint_Site_URL = $Get_Sharepoint_Content.Infos.Site_URL 

				if (($Sharepoint_Folder -ne $null) -and ($Sharepoint_App_ID -ne $null) -and ($Sharepoint_App_Secret -ne $null) -and ($Sharepoint_Site_URL -ne $null)) {
					powershell "$current_folder\Actions_scripts\Collect_Logs.ps1"
					powershell "$current_folder\Actions_scripts\Upload_Logs_Sharepoint.ps1" 
				}
			}
			elseif ($Send_Logs_Method -eq "Mail") {
				if ($Support_Mail -ne $null) {
					powershell "$current_folder\Actions_scripts\Collect_Logs.ps1" 
					$CompName = $env:COMPUTERNAME
					# $Logs_Collect_Folder = "C:\Device_Logs_From" + "_$CompName"
					$Logs_Collect_Folder = "$env:temp\Device_Logs_From" + "_$CompName" 
					$Logs_Collect_Folder_ZIP = "$Logs_Collect_Folder" + ".zip"
 
					$User_Name = $env:USERNAME
					$Computer_Name = $env:COMPUTERNAME
					$Subject = "Logs sent from $User_Name on device $Computer_Name"
					$Body = "Logs sent from $User_Name on device $Computer_Name" 
					$Outlook = New-Object -ComObject Outlook.Application
					$Mail = $Outlook.CreateItem(0)
					$Mail.To = $Support_Mail 
					$mail.Attachments.Add($Logs_Collect_Folder_ZIP)
					$Mail.Subject = $Subject 
					$Mail.Body = $Body
					$Mail.Send()
					$Outlook.Quit()
					[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null

					# remove-item $Logs_Collect_Folder -Force -Recurse
					# remove-item $Logs_Collect_Folder_ZIP -Force
				}
			}
		}
	)
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	$AdminMenu = $contextmenu.Items.Add("Admin");
	$AdminMenu_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\portal.png")
	$AdminMenu.Image = $AdminMenu_Img
} else {
	$AdminMenu = $contextmenu.Items.Add("Admin (enter pw)");
	$AdminMenu_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\portal.png")
	$AdminMenu.Image = $AdminMenu_Img
}

$Menu_Exit = $contextmenu.Items.Add("Exit");
$Menu_Exit_Img = [System.Drawing.Bitmap]::FromFile("$Systray_Pictures\exit.png")
$Menu_Exit.Image = $Menu_Exit_Img

$Systray_Tool_Icon.ContextMenuStrip = $contextmenu;

Set-Location $current_folder

$Systray_Tool_Icon.Add_Click(
	{
		if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
			powershell -sta "$Current_Folder\About_this_computer.ps1"
		}
	}
)

$Run_Tool.Add_Click(
	{
		powershell -sta "$Current_Folder\About_this_computer.ps1"
	}
)

# When Exit is clicked, close everything and kill the PowerShell process
$Menu_Exit.add_Click(
	{
		$Systray_Tool_Icon.Visible = $false
		Stop-Process $pid
	}
)

# Make PowerShell Disappear
# $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
# $asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
# $null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()

# Create an application context for it to all run within.
# This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)