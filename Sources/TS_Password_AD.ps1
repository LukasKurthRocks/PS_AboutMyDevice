param (
	[string]$AD_Server,
	[string]$Group
)

try {
	[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | out-null
	[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
	
	$AssemblyLocation = Join-Path -Path $PSScriptRoot -ChildPath .\assembly
	foreach ($Assembly in (Get-ChildItem $AssemblyLocation -Filter *.dll)) {
		[System.Reflection.Assembly]::LoadFrom($Assembly.FullName) | Out-Null
	}
	
	#[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll') | out-null
	#[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll') | out-null
}
catch {
	Write-Host "Exception occured: $($_.Exception.Message)" -BackgroundColor Black -ForegroundColor Red
	return
}

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$XamlLayoutFileName = "TS_Password_AD.xaml"
$XamlLayoutFile = "$PSScriptRoot\$XamlLayoutFileName"

Write-Verbose "Loading GUI from: $($XamlLayoutFile)"
try {
	[xml]$XAML = ( (Get-Content -Path $XamlLayoutFile -Encoding UTF8) )

	#$XAML=(New-Object System.Xml.XmlDocument)
	#$XAML.Load("$XamlLayoutFile")
	#$XAML | Out-Host
	#Write-Host "XAML: $XAML"

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
			Write-Host "We do not have a MetroWindow property"
			return
		}
	}

	$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
	$Window = [Windows.Markup.XamlReader]::Load($Reader)
}
catch {
	Write-Host "Error declaring GUI: $($_.Exception.Message)" -ForegroundColor Red
	#$_
	return
}

#########################################################################
#                        BUTTONS AND LABELS INITIALIZATION              #
#########################################################################

# Load XML variables
$XAML.SelectNodes("//*") | ForEach-Object {
	try {
		Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script
	}
	catch {
		Write-Host "$($_.Exception.Message)" -ForegroundColor Red
	}
}


if ($AD_Server -eq "") {
	[System.Windows.Forms.MessageBox]::Show("Please specify the AD server parameter: -AD_Server", "Oops, Missing parameter") | out-null
	break
}

if ($Group -eq "") {
	[System.Windows.Forms.MessageBox]::Show("Please specify the authorized AD group parameter: -Group", "Oops, Missing parameter") | out-null
	break
}

$module_name = "ActiveDirectory"
try {
	if (!(Get-Module -listavailable | Where-Object { $_.name -like "*$module_name*" })) {
		[System.Windows.Forms.MessageBox]::Show("The ActiveDirectory module does not exist.`Please check you have correctly integrated it into your boot image.", "Oops, ActiveDirectory module error")
		break
	}
	else {
		Import-Module $module_name -ErrorAction SilentlyContinue
	}
}
catch {
	[System.Windows.Forms.MessageBox]::Show("An issue occured while importing the ActiveDirectory module.", "Oops, ActiveDirectory module error")
	break
}

$TS_Deploy_Group = $Group

$Enter_TS.Add_Click( {
		
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
				[System.Windows.Forms.MessageBox]::Show("The user $Get_User has not been found", "User not found")
			}
			catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
				[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")
			}
			catch [System.Security.Authentication.AuthenticationException] {
				[System.Windows.Forms.MessageBox]::Show("Please check the admin user name or password", "Invalid credentials")
			}
			catch {
				if ($AD_Server -ne "") {
					[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")
				}
			}
				
			if ($AD_User_Status -eq $True) {
				$Get_User_Groups = (Get-ADPrincipalGroupMembership ($Get_AD_User_Name.SamAccountName)-server $AD_Server -Credential $Creds)
				if ($Get_User_Groups.SamAccountName -contains $TS_Deploy_Group) {
					$Script:Password_Status = $True
				}
				else {
					$Script:Password_Status = $False
					[System.Windows.Forms.MessageBox]::Show("The specified user is not member of the group: $TS_Deploy_Group", "Unauthorized user")
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
					[System.Windows.Forms.MessageBox]::Show("You typed 5 bad passwords !!!`nYour computer will now exit the TS and reboot !!!", "Oops, Access denied")
					$Script:Five_Bad_PWD = $True
					$Window.Close()
					Start-Process -FilePath "wpeutil" -ArgumentList "reboot"
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
							[System.Windows.Forms.MessageBox]::Show("One last account attempt", "User account error")
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
			[System.Windows.Forms.MessageBox]::Show("Please type a user name and password !!!", "Oops, Something is missing")
		}
	}
)

$Window.Add_Closing(
	{
		if ($Password_Status -eq $True) {
			[System.Windows.Forms.MessageBox]::Show("TS will continue to the next step", "TS Password unlocked")
		}
		elseif ($Five_Bad_PWD -ne $True) {
			$_.Cancel = $true
			[System.Windows.Forms.MessageBox]::Show("You can not start the TS without the correct password !!!", "TS Passord required")
		}
	}
)

$Change_Theme.Add_Click(
	{
		$Theme = [MahApps.Metro.ThemeManager]::DetectAppStyle($Window)
		$my_theme = ($Theme.Item1).name
		if ($my_theme -eq "BaseLight") {
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($Window, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseDark"));
		}
		elseif ($my_theme -eq "BaseDark") {
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($Window, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseLight"));
		}
	}
)

$Window.ShowDialog() | Out-Null