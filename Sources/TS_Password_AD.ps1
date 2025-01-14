param (
	[string]$AD_Server,
	[string]$Group
)

function ShowError {
	param(
		[string]$ErrorMessage
	)

	#[System.Windows.Forms.MessageBox]::Show($ErrorMessage, $ErrorTitle) | Out-Null
	Write-Host "$ErrorMessage" -BackgroundColor Black -ForegroundColor Red
}

try {
	[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
	[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
	
	$AssemblyLocation = Join-Path -Path $PSScriptRoot -ChildPath .\assembly
	foreach ($Assembly in (Get-ChildItem $AssemblyLocation -Filter *.dll)) {
		[System.Reflection.Assembly]::LoadFrom($Assembly.FullName) | Out-Null
	}
	
	#[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll') | Out-Null
	#[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll') | Out-Null
}
catch {
	ShowError "Exception occured: $($_.Exception.Message)" -BackgroundColor Black -ForegroundColor Red
	return
}

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$XamlLayoutFileName = "TS_Password_AD.xaml"
$XamlLayoutFile = "$PSScriptRoot\$XamlLayoutFileName"

function LoadXAML {
	[CmdLetBinding()]
	param($XAMLFile)

	Write-Verbose "Loading GUI from: $($XamlLayoutFile)"

	if (!(Test-Path -Path "$XAMLFile")) {
		ShowError "XAML File '$XAMLFile' could not be found."
		exit
	}

	[xml]$script:XAML = ( (Get-Content -Path $XAMLFile -Encoding UTF8) )

	# Remove XML attributes that break a couple things.
	#   Without this, you must manually remove the attributes
	#   after pasting from Visual Studio. If more attributes
	#   need to be removed automatically, add them below.
	$AttributesToRemove = @(
		'x:Class',
		'mc:Ignorable'
	)

	# Standard: Window, main is MetroWindow this time
	foreach ($Attrib in $AttributesToRemove) {
		if ($XAML.MetroWindow) {
			if ($XAML.MetroWindow.GetAttribute($Attrib)) {
				$XAML.MetroWindow.RemoveAttribute($Attrib)
			}
		}
		else {
			ShowError "We do not have a MetroWindow property"
			return
		}
	}

	$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
	$script:Window = [Windows.Markup.XamlReader]::Load($Reader)
	
	# Load XML variables
	$XAML.SelectNodes("//*") | ForEach-Object {
		try {
			Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script
		}
		catch {
			ShowError "$($_.Exception.Message)"
		}
	}
}

try {
	LoadXAML -XAMLFile $XamlLayoutFile -Verbose:$VerbosePreference
}
catch {
	ShowError "Error declaring GUI: $($_.Exception.Message)"
	return
}

#########################################################################
#                        BUTTONS AND LABELS INITIALIZATION              #
#########################################################################

if ($AD_Server -eq "") {
	ShowError "Please specify the AD server parameter: -AD_Server"
	#[System.Windows.Forms.MessageBox]::Show("Please specify the AD server parameter: -AD_Server", "Oops, Missing parameter") | Out-Null
	#break
}

if ($Group -eq "") {
	ShowError "Please specify the authorized AD group parameter: -Group"
	#[System.Windows.Forms.MessageBox]::Show("Please specify the authorized AD group parameter: -Group", "Oops, Missing parameter") | Out-Null
	#break
}

$module_name = "ActiveDirectory"
try {
	if (!(Get-Module -listavailable | Where-Object { $_.name -like "*$module_name*" })) {
		ShowError "The ActiveDirectory module does not exist."
		#[System.Windows.Forms.MessageBox]::Show("The ActiveDirectory module does not exist.", "Oops, ActiveDirectory module error")
		#break
	}
	else {
		Import-Module $module_name -ErrorAction SilentlyContinue
	}
}
catch {
	ShowError "An issue occured while importing the ActiveDirectory module."
	#[System.Windows.Forms.MessageBox]::Show("An issue occured while importing the ActiveDirectory module.", "Oops, ActiveDirectory module error")
	#break
}

$TS_Deploy_Group = $Group
$Bad_PWD_Count = 0
$Five_Bad_PWD = $false

$Enter_TS.Add_Click(
	{	
		$Get_User = $Typed_User.Text
		$Get_PWD = $Typed_PWD.Password

		if (($Get_User -ne "") -and ($Get_PWD -ne "")) {
			$Script:PWD_Max_Test = 5

			$User_PWD = ConvertTo-SecureString -String $Get_PWD -AsPlainText -Force
			$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Get_User, $User_PWD)

			$AD_User_Status = $False
			try {
				$Get_AD_User_Name = Get-ADUser $Get_User -server $AD_Server -Credential $Creds
				$AD_User_Status = $True
			}
			catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
				#[System.Windows.Forms.MessageBox]::Show("The user $Get_User has not been found", "User not found")
				ShowError "The user $Get_User has not been found"
			}
			catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
				#[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")
				ShowError "Check the server name or IP configuration"
			}
			catch [System.Security.Authentication.AuthenticationException] {
				#[System.Windows.Forms.MessageBox]::Show("Please check the admin user name or password", "Invalid credentials")
				ShowError "Please check the admin user name or password"
			}
			catch {
				if ($AD_Server -ne "") {
					#[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")
					ShowError "Check the server name or IP configuration"
				}
			}
				
			if ($AD_User_Status -eq $True) {
				$Get_User_Groups = (Get-ADPrincipalGroupMembership ($Get_AD_User_Name.SamAccountName)-server $AD_Server -Credential $Creds)
				if ($Get_User_Groups.SamAccountName -contains $TS_Deploy_Group) {
					$Script:Password_Status = $True
				}
				else {
					$Script:Password_Status = $False
					#[System.Windows.Forms.MessageBox]::Show("The specified user is not member of the group: $TS_Deploy_Group", "Unauthorized user")
					ShowError "The specified user is not member of the group: $TS_Deploy_Group"
				}
			}

			if ($Password_Status -eq $True) {
				$Window.Close()
				$Bad_PWD_Count = $Bad_PWD_Count + 1

				switch ($Bad_PWD_Count) {
					1 {
						$Password_1.Foreground = "#00a300"
						$Password_1.Kind = "LockOpenOutline"
						$Lock1.BorderBrush = "#00a300"
					}
					2 { 
						$Password_2.Foreground = "#00a300"
						$Password_2.Kind = "LockOpenOutline"
						$Lock2.BorderBrush = "#00a300"
					}
					3 { 
						$Password_3.Foreground = "#00a300"
						$Password_3.Kind = "LockOpen"
						$Lock3.BorderBrush = "#00a300"
					}
					4 { 
						$Password_4.Foreground = "#00a300"
						$Password_4.Kind = "LockOpen"
						$Lock4.BorderBrush = "#00a300"
					}
					5 { 
						$Password_5.Foreground = "#00a300"
						$Password_5.Kind = "LockOpen"
						$Lock5.BorderBrush = "#00a300"
					}
				}
			}
			else {
				$Script:Password_Status = $False
				$Script:Bad_PWD_Count += 1
				if ($PWD_Max_Test -le $Bad_PWD_Count) {
					#[System.Windows.Forms.MessageBox]::Show("You typed 5 bad passwords !!!`nYour computer will now exit the TS and reboot !!!", "Oops, Access denied")
					ShowError "You typed 5 bad passwords!!!"
					$Script:Five_Bad_PWD = $True
					$Window.Close()
					#Start-Process -FilePath "wpeutil" -ArgumentList "reboot"
				}
				else {
					$Script:Five_Bad_PWD = $False
					switch ($Bad_PWD_Count) {
						1 {
							$Password_1.Foreground = "Red"
							$Lock1.BorderBrush = "Red"
						}
						2 { 
							$Password_2.Foreground = "Red"
							$Lock2.BorderBrush = "Red"
						}
						3 { 
							$Password_3.Foreground = "Red"
							$Lock3.BorderBrush = "Red"
						}
						4 { 
							$Password_4.Foreground = "Red"
							$Lock4.BorderBrush = "Red"
							#[System.Windows.Forms.MessageBox]::Show("One last account attempt", "User account error")
							ShowError "One last account attempt"
						}
						5 { 
							$Password_5.Foreground = "Red"
							$Lock5.BorderBrush = "Red"
						}
					}
				}
			}
		}
		else {
			#[System.Windows.Forms.MessageBox]::Show("Please type a user name and password !!!", "Oops, Something is missing")
			ShowError "Please type a user name and password !!!"
		}
	}
)

$Window.Add_Closing(
	{
		if ($Password_Status -eq $True) {
			#[System.Windows.Forms.MessageBox]::Show("TS will continue to the next step", "TS Password unlocked")
			Write-Host "TODO: TS PW Unlocked"
		}
		elseif ($Five_Bad_PWD -ne $True) {
			$_.Cancel = $true
			#[System.Windows.Forms.MessageBox]::Show("You can not start the TS without the correct password !!!", "TS Passord required")
			Write-Host "TODO: TS PW Required"
		}
	}
)

$Change_Theme.Add_Click(
	{
		$PossibleThemes = @("BaseLight", "BaseDark")
		$CurrentTheme = [MahApps.Metro.ThemeManager]::DetectAppStyle($Window)
		
		$RandomTheme = Get-Random -InputObject ($PossibleThemes | Where-Object { $_ -ne ($CurrentTheme.Item1).name })
		[MahApps.Metro.ThemeManager]::ChangeAppStyle($Window, $CurrentTheme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme($RandomTheme)) 
	}
)

if ($Window.ShowDialog()) {
	Write-Host "Successfully processed dialog."
}
else {
	Write-Host "Window/Dialog not processed successfully."
}