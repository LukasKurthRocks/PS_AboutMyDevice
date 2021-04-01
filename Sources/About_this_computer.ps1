#================================================================================================================
# Author : Lukas Kurth Rocks
#================================================================================================================

try {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null

    $AssemblyLocation = Join-Path -Path $PSScriptRoot -ChildPath .\assembly
    foreach ($Assembly in (Get-ChildItem $AssemblyLocation -Filter *.dll)) {
        [System.Reflection.Assembly]::LoadFrom($Assembly.FullName) | Out-Null
    }

    #[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll') | Out-Null
    #[System.Reflection.Assembly]::LoadFrom('assembly\LiveCharts.dll') | Out-Null
    #[System.Reflection.Assembly]::LoadFrom('assembly\LiveCharts.Wpf.dll') | Out-Null
    #[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll') | Out-Null
    #[System.Reflection.Assembly]::LoadFrom('assembly\LoadingIndicators.WPF.dll') | Out-Null
}
catch {
    Write-Host "Exception occured: $($_.Exception.Message)" -BackgroundColor Black -ForegroundColor Red
    return
}
#return

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$XamlLayoutFileName = "About_this_computer.xaml"
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

# Load XML variables
$XAML.SelectNodes("//*") | ForEach-Object {
    try {
        Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script
    }
    catch {
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    }
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

$Storage_Design.Add_Click(
    {
        if ($Storage_Design.IsChecked -eq $True) {
            $Chart.Visibility = "Visible"
            $Bar.Visibility = "Collapsed"
        }
        else {
            $Chart.Visibility = "Collapsed"
            $Bar.Visibility = "Visible"
        }
    }
)

$Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path

#########################################################################
#                        PROGRESSBAR DESIGN USER                        #
#########################################################################

$syncProgress = [hashtable]::Synchronized(@{})
$childRunspace = [runspacefactory]::CreateRunspace()
$childRunspace.ApartmentState = "STA"
$childRunspace.ThreadOptions = "ReuseThread" 
$childRunspace.Open()
$childRunspace.SessionStateProxy.SetVariable("syncProgress", $syncProgress)
$PsChildCmd = [PowerShell]::Create().AddScript(
    {
        [xml]$xaml = @"
<Controls:MetroWindow 
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:i="http://schemas.microsoft.com/expression/2010/interactivity"
xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"
xmlns:loadin="clr-namespace:LoadingIndicators.WPF;assembly=LoadingIndicators.WPF"
Name="WindowProgress" 
WindowStyle="None" 
AllowsTransparency="True" 
UseNoneWindowStyle="True"
Width="650" 
Height="400" 
WindowStartupLocation ="CenterScreen"
Topmost="true"
BorderBrush="Gray"
>

<Window.Resources>
<ResourceDictionary>
<ResourceDictionary.MergedDictionaries>
<!-- LoadingIndicators resources -->
<ResourceDictionary Source="pack://application:,,,/LoadingIndicators.WPF;component/Styles.xaml"/>
<!-- Mahapps resources -->
<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Controls.xaml" />
<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Fonts.xaml" />
<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Colors.xaml" />
<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/Cobalt.xaml" />
<ResourceDictionary Source="pack://application:,,,/MahApps.Metro;component/Styles/Accents/BaseDark.xaml" />
</ResourceDictionary.MergedDictionaries>
</ResourceDictionary>
</Window.Resources>

<Window.Background>
<SolidColorBrush Opacity="0.7" Color="#0077D6"/>
</Window.Background>

<Grid>
<StackPanel Orientation="Vertical" VerticalAlignment="Center" HorizontalAlignment="Center">
<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,0,0,0">
<!--<Controls:ProgressRing IsActive="True" Margin="0,0,0,0"Foreground="White" Width="50"/> -->
<loadin:LoadingIndicator Margin="0,5,0,0" Name="ArcsRing" SpeedRatio="1" Foreground="White" IsActive="True" Style="{DynamicResource LoadingIndicatorArcsRingStyle}"/>
</StackPanel>

<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,20,0,0">
<Label Name="ProgressStep" Content="Getting information about your device" FontSize="17" Margin="0,0,0,0" Foreground="White"/>
</StackPanel>
</StackPanel>

</Grid>
</Controls:MetroWindow>
"@

        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $syncProgress.Window = [Windows.Markup.XamlReader]::Load( $reader )
        $syncProgress.Label = $syncProgress.window.FindName("ProgressStep")

        $syncProgress.Window.ShowDialog()#| Out-Null
        $syncProgress.Error = $Error
    }
)

################ Launch Progress Bar ########################
function Launch_modal_progress { 
    $PsChildCmd.Runspace = $childRunspace
    $Script:Childproc = $PsChildCmd.BeginInvoke()

}

################ Close Progress Bar ########################
function Close_modal_progress {
    $syncProgress.Window.Dispatcher.Invoke([action] { $syncProgress.Window.close() })
    $PsChildCmd.EndInvoke($Script:Childproc) | Out-Null
}


#########################################################################
#                        PROGRESSBAR DESIGN USER                        #
#########################################################################

# if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
# $Win32_LogicalDisk = Get-CimInstance Win32_LogicalDisk | where {$_.DriveType -eq "3"}
# }
# else {
# $Win32_LogicalDisk = Get-WmiObject Win32_LogicalDisk | where {$_.DriveType -eq "3"}
# }
# if(($Win32_LogicalDisk.count)-gt 1)
# {
# foreach ($disk in $Win32_LogicalDisk)### Enum Disk 
# {
# $Disk_Caption = $disk.deviceid
# $Total_size = [Math]::Round(($disk.size/1GB),1)
# $Free_size = [Math]::Round(($disk.Freespace/1GB),1)
# $Disk_information =$Disk_information + "(" + $disk.deviceid + ")" + $Total_size + " GB Total / " ++ $Free_size + " GB Free `n"
# }
# }
# else
# {
# $Total_size = [Math]::Round(($Win32_LogicalDisk.size/1GB),1)
# $Free_size = [Math]::Round(($Win32_LogicalDisk.Freespace/1GB),1)
# $Disk_information = $Disk_information + "(" + $Win32_LogicalDisk.deviceid + ")" + $Total_size + " GB Total / " ++ $Free_size + " GB Free"
# }
# $Disk_information = $Disk_information.trim()

if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
    $Win32_ComputerSystem = Get-CimInstance Win32_ComputerSystem
}
else {
    $Win32_ComputerSystem = Get-WmiObject Win32_ComputerSystem
}

#########################################################################
#                        INFORMATIONS FROM DETAILS PART                 #
#########################################################################

function Get_Details_Infos {
    # Get printer infos
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Win32_Printer = Get-CimInstance -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    }
    else {
        $Win32_Printer = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    }
    $Printer.Content = $Win32_Printer.name

    # Get BIOS infos
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Win32_BIOS = Get-CimInstance Win32_BIOS
    }
    else {
        $Win32_BIOS = Get-WmiObject Win32_BIOS
    }
    $BIOS_Version.Content = $Win32_BIOS.SMBIOSBIOSVersion

    # Check drivers part
    $Check_Drivers_Block.Visibility = "Collapsed"
    $Missing_Drivers_Block.Visibility = "Collapsed"

    # if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
    # $Drivers_Test = Get-CimInstance Win32_PNPEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 }
    # }
    # else {
    # $Drivers_Test = Get-WmiObject Win32_PNPEntity | Where-Object {$_.ConfigManagerErrorCode -gt 0 }
    # }
    # $Search_Missing_Drivers = ($Drivers_Test | Where-Object {$_.ConfigManagerErrorCode -eq 28}).Count

    # if ($Search_Missing_Drivers -gt 0) {
    # $Check_Drivers_Block.Visibility = "Visible"
    # $Missing_Drivers_Block.Visibility = "Visible"
    # $Missing_Drivers_Label.Content = "$Search_Missing_Drivers drivers manquants"
    # $Missing_Drivers_Label.Foreground = "Yellow"
    # $Missing_Drivers_Label.Fontweight = "Bold"
    # } else {
    # $Missing_Drivers_Block.Visibility = "Collapsed"
    # $Check_Drivers_Block.Visibility = "Collapsed"
    # }

    ################# Test if Domain or Network#################
    if (($Win32_ComputerSystem.partofdomain -eq $True)) {
        $Domain_WKG_Label.Content = "Domain:"
        $Domain_test = $env:USERDNSDOMAIN;
    }
    else {
        $Domain_WKG_Label.Content = "Workgroup name :"
        $Domain_test = $Win32_ComputerSystem.Workgroup 
        $AD_Site_Name = "None"
        if ($null -eq $Domain_part_label) {
            Write-Host "Error: `$Domain_part_label not found!" -BackgroundColor Black -ForegroundColor Red
        }
        else {
            $Domain_part_label.Visibility = "Collapsed"
        }
        if ($null -eq $Domain_part_Infos) {
            Write-Host "Error: `$Domain_part_Infos not found!" -BackgroundColor Black -ForegroundColor Red
        }
        else {
            $Domain_part_Infos.Visibility = "Collapsed"
        }
        if ($null -eq $My_Site_Name) {
            Write-Host "Error: `$My_Site_Name not found!" -BackgroundColor Black -ForegroundColor Red
        }
        else {
            $My_Site_Name.Visibility = "Collapsed"
        }
    }

    # Get network infos
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $win32_networkadapterconfiguration = Get-CimInstance -class "Win32_NetworkAdapterConfiguration" | Where-Object { $_.IPEnabled -Match "True" }
    }
    else {
        $win32_networkadapterconfiguration = Get-WmiObject -class "Win32_NetworkAdapterConfiguration" | Where-Object { $_.IPEnabled -Match "True" }
    }
    if ($null -eq $win32_networkadapterconfiguration) {
        $My_IP.content = "Not connected"
    }
    else {
        foreach ($obj in $win32_networkadapterconfiguration) {
            $MAC_Address = $obj.MACAddress
            $IP_Subnet = $obj.IPsubnet[0]
            $IP_Address = $obj.IPAddress[0]
        }
    }

    # Get default printer
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Win32_Printer = Get-CimInstance -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    }
    else {
        $Win32_Printer = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    }
    $Default_printer = $Win32_Printer.name

    # Get installed antivirus
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Get_Antivirus = Get-CimInstance -Namespace root/SecurityCenter2 -Class AntiVirusProduct
    }
    else {
        $Get_Antivirus = Get-WmiObject -Namespace root/SecurityCenter2 -Class AntiVirusProduct
    }
    #foreach ($antivirus in $Get_Antivirus) {
    #    $Antivirus_list = $Antivirus_list + $antivirus.displayname + " "
    #}
    $CurrentAntivirusSolution = $Get_Antivirus | Sort-Object timestamp -Descending | Select-Object -First 1

    if ($CurrentAntivirusSolution.displayName -eq "Windows Defender") {
        # Get defender antivirus options
        $Get_WinDefender = Get-MpComputerStatus
        if ((($Get_WinDefender.AntispywareEnabled) -ne $True) -and (($Get_WinDefender.AntivirusEnabled) -ne $True)) {
            $antivirus_Status_Label.Content = "Antispyware and Antivirus disabled"
            $antivirus_Status_Label.Foreground = "yellow"
            $antivirus_Status_Label.Fontweight = "bold"
        }
        elseif ((($Get_WinDefender.AntispywareEnabled) -eq $True) -and (($Get_WinDefender.AntivirusEnabled) -eq $True)) {
            $antivirus_Status_Label.Content = "Antispyware and Antivirus enabled"
        }
        else {
            if (($Get_WinDefender.AntispywareEnabled) -ne $True) {
                $antivirus_Status_Label.Content = "Antispyware disabled"
                $antivirus_Status_Label.Foreground = "yellow"
                $antivirus_Status_Label.Fontweight = "bold"
            }
            elseif (($Get_WinDefender.AntivirusEnabled) -ne $True) {
                $antivirus_Status_Label.Content = "Antivirus disabled"
                $antivirus_Status_Label.Foreground = "yellow"
                $antivirus_Status_Label.Fontweight = "bold"
            }
        }

        if ((($Get_WinDefender.AntispywareSignatureAge) -gt "3") -and (($Get_WinDefender.AntivirusSignatureAge) -gt "3")) {
            $antivirus_Last_Update_Label.Content = "Antispyware and Antivirus not up to date"
            $antivirus_Last_Update_Label.Foreground = "yellow"
            $antivirus_Last_Update_Label.Fontweight = "bold"
        }
        elseif ((($Get_WinDefender.AntispywareSignatureAge) -lt 3) -and (($Get_WinDefender.AntivirusSignatureAge) -lt 3)) {
            $antivirus_Last_Update_Label.Content = "Antispyware et Antivirus up to date"
            $antivirus_Last_Update_Label.Fontweight = "Normal"
        }
        else {
            if (($Get_WinDefender.AntispywareEnabled) -ne $True) {
                $antivirus_Last_Update_Label.Content = "Antispyware not up to date"
                $antivirus_Last_Update_Label.Foreground = "yellow"
                $antivirus_Last_Update_Label.Fontweight = "bold"
            }
            elseif (($Get_WinDefender.AntivirusEnabled) -ne $True) {
                $antivirus_Last_Update_Label.Content = "Antivirus not up to date"
                $antivirus_Last_Update_Label.Foreground = "yellow"
                $antivirus_Last_Update_Label.Fontweight = "bold"
            }
        }

        $antivirus_Last_Scan_Block.Visibility = "Collapsed"
        $Check_LastScan_Block.Visibility = "Collapsed"

        if ((($Get_WinDefender.FullScanAge) -gt "10") -and (($Get_WinDefender.QuickScanAge) -gt "10")) {
            $antivirus_Last_Scan_Label.Content = "Last antivirus check > 10 days"
            $antivirus_Last_Scan_Label.Foreground = "yellow"
            $antivirus_Last_Update_Label.Fontweight = "normal"
            $antivirus_Last_Scan_Block.Visibility = "Visible"
            $Check_LastScan_Block.Visibility = "Visible"
        }
        elseif ((($Get_WinDefender.FullScanAge) -lt 1) -or (($Get_WinDefender.QuickScanAge) -lt 1)) {
            $antivirus_Last_Scan_Block.Visibility = "Collapsed"
            $Check_LastScan_Block.Visibility = "Collapsed"
        }
    }
    else {
        # Switch to determine the status of antivirus definitions and real-time protection.
        # The values in this switch-statement are retrieved from the following website: http://community.kaseya.com/resources/m/knowexch/1020.aspx
        switch ($CurrentAntivirusSolution.productState) {
            "262144" { $AVDefStatus = "Up to date" ; $AVRTStatus = "Disabled" }
            "262160" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Disabled" }
            "266240" { $AVDefStatus = "Up to date" ; $AVRTStatus = "Enabled" }
            "266256" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Enabled" }
            "393216" { $AVDefStatus = "Up to date" ; $AVRTStatus = "Disabled" }
            "393232" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Disabled" }
            "393488" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Disabled" }
            "397312" { $AVDefStatus = "Up to date" ; $AVRTStatus = "Enabled" }
            "397328" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Enabled" }
            "397584" { $AVDefStatus = "Out of date" ; $AVRTStatus = "Enabled" }
            default { $AVDefStatus = "Unknown" ; $AVRTStatus = "Unknown" }
        }
    
        if ($AVRTStatus -eq "Disabled" -and $AVDefStatus -eq "Out of date") {
            # Disabled and Out Of Date
            $antivirus_Status_Label.Content = "Antivirus disabled and out of date"
            $antivirus_Status_Label.Foreground = "yellow"
            $antivirus_Status_Label.Fontweight = "bold"
        }
        elseif ($AVRTStatus -eq "Enabled" -and $AVDefStatus -eq "Out of date") {
            # Enabled and Out Of Date
            $antivirus_Status_Label.Content = "Antivirus enabled, but out of date"
            $antivirus_Status_Label.Foreground = "yellow"
            $antivirus_Status_Label.Fontweight = "bold"
        }
        else {
            if ($AVRTStatus -eq "Disabled") {
                # Disabled and Up To Date
                $antivirus_Status_Label.Content = "Antivirus disabled"
                $antivirus_Status_Label.Foreground = "yellow"
                $antivirus_Status_Label.Fontweight = "bold"
            }
            else {
                # Enabled and Up To Date
                $antivirus_Status_Label.Content = "Antivirus enabled ($($CurrentAntivirusSolution.displayName))"
            }
        }
        
        $antivirus_Last_Scan_Block.Visibility = "Collapsed"
        $Check_LastScan_Block.Visibility = "Collapsed"
        
        $AVDefinitionTimeStamp = [DateTime]$CurrentAntivirusSolution.timestamp
        $AVDefinitionTimeString = $AVDefinitionTimeStamp.ToString([cultureinfo]::CreateSpecificCulture((Get-Culture)))
        $AVDefinitionUpdateTimeSpan = New-TimeSpan -Start $AVDefinitionTimeStamp -End (Get-Date)

        if ($AVDefinitionUpdateTimeSpan.Days -gt 10) {
            $antivirus_Last_Update_Label.Content = "Last definitions: $AVDefinitionTimeString"
            $antivirus_Last_Update_Label.Fontweight = "bold"
            
            $antivirus_Last_Scan_Block.Visibility = "Collapsed"
            $Check_LastScan_Block.Visibility = "Collapsed"
        }
        elseif ($AVDefinitionUpdateTimeSpan.Days -lt 1) {
            $antivirus_Last_Update_Label.Content = "Last definitions: $AVDefinitionTimeString"
            
            $antivirus_Last_Scan_Block.Visibility = "Collapsed"
            $Check_LastScan_Block.Visibility = "Collapsed"
        }
    }
    
    $My_IP.content = "$IP_Address" + " / " + "$IP_Subnet"
    $My_MAC.content = "$MAC_Address"
    $Domain_name.content = "$Domain_test"

    $Chart.Visibility = "Visible"
    $Bar.Visibility = "Collapsed"
    
    # Get Graphic Cards info
    $Graphic_Card_info = (Get-CimInstance CIM_VideoController)
    if (($Graphic_Card_info.count) -gt 1) {
        foreach ($Card in $Graphic_Card_info) {
            ### Enum Disk 
            $Graphic_Caption = $Card.Caption
            $Graphic_DriverVersion = $Card.DriverVersion
            $Graphic_Cards_with_DriverVersion = $Graphic_Cards + $Graphic_Caption + " ($Graphic_DriverVersion)" + "`n"
            $Graphic_Cards = $Graphic_Cards + $Graphic_Caption + "`n"
        }
    }
    else {
        $Graphic_Caption = $Graphic_Card_info.Caption
        $Graphic_DriverVersion = $Graphic_Card_info.DriverVersion
        $Graphic_Cards_with_DriverVersion = $Graphic_Cards + $Graphic_Caption + " ($Graphic_DriverVersion)" + "`n"
        $Graphic_Cards = $Graphic_Cards + $Graphic_Caption + "`n"
    }
    $Graphic_Cards = $Graphic_Cards.trim()
    $Graphic_Cards_with_DriverVersion = $Graphic_Cards_with_DriverVersion.trim()
    $Graphisme.Content = $Graphic_Cards
    $Graphic_Card_details.Content = $Graphic_Cards_with_DriverVersion

    # Get Graphic Wifi info + Translation
    $Wifi_Card_Info = (Get-NetAdapter -Name WLAN, WI-FI -ErrorAction SilentlyContinue)
    if (($Wifi_Card_Info.count) -eq 0) {
        $Wifi_Card.Content = "N/A"
    }
    else {
        if (($Wifi_Card_Info.count) -gt 1) {
            foreach ($Card in $Wifi_Card_Info) {
                ### Enum Disk 
                $Wifi_Caption = $Card.InterfaceDescription
                $Wifi_Driver_Version = $Card.DriverVersion
                $Wifi_Cards = $Wifi_Cards + $Wifi_Caption + " ($Wifi_Driver_Version)" + "`n"
            }
        }
        else {
            $Wifi_Caption = $Wifi_Card_Info.InterfaceDescription
            $Wifi_Driver_Version = $Wifi_Card_Info.DriverVersion
            $Wifi_Cards = $Wifi_Cards + $Wifi_Caption + " ($Wifi_Driver_Version)" + "`n"
        }
        $Wifi_Cards = $Wifi_Cards.trim()
        $Wifi_Card.Content = $Wifi_Cards
    }
}

#########################################################################
#                        INFORMATIONS FROM DETAILS PART                 #
#########################################################################

#########################################################################
#                        INFORMATIONS FROM OVERVIEWPART                 #
#########################################################################

function Get_Overview_Infos {
    $User = $env:USERPROFILE
    $ProgData = $env:PROGRAMDATA
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Win32_BIOS = Get-CimInstance Win32_BIOS
    }
    else {
        $Win32_BIOS = Get-WmiObject Win32_BIOS
    }
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $Win32_OperatingSystem = Get-CimInstance Win32_OperatingSystem
    }
    else {
        $Win32_OperatingSystem = Get-WmiObject Win32_OperatingSystem
    }
    $Manufacturer = $Win32_ComputerSystem.Manufacturer
    $MTM = $Win32_ComputerSystem.Model
    $Serial_Number = $Win32_BIOS.SerialNumber
    $Memory_RAM = [Math]::Round(($Win32_ComputerSystem.TotalPhysicalMemory / 1GB), 1)
    $REG_OS_Version = Get-ItemProperty -Path registry::"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue

    $OS_Ver = $Win32_OperatingSystem.version
    $Build_number = $Win32_OperatingSystem.buildnumber
    if ($OS_Ver -like "10*") {
        $OS_ReleaseID = $REG_OS_Version.ReleaseID
        $OS_DisplayVersion = $REG_OS_Version.DisplayVersion
        if ($null -ne $OS_DisplayVersion) {
            $Release = $OS_DisplayVersion
        }
        else {
            $Release = $OS_ReleaseID
        }
    }
    else {
        $Release = ""
    }

    if ($Manufacturer -like "*lenovo*") {
        #if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        #    $Computer_Model = ((Get-CimInstance -Class:Win32_ComputerSystem).Model).Substring(0,4)
        #}
        #else {
        #    $Computer_Model = ((Get-WmiObject -Class:Win32_ComputerSystem).Model).Substring(0,4)
        #}
        $Computer_Model = ($Win32_ComputerSystem.Model).Substring(0, 4)
    }
    else {
        $Computer_Model = ($Win32_ComputerSystem.Model)
    }
    $Device_Model.Content = "Computer model: $Computer_Model"

    $Ma_Machine.Content = "Device name: " + $env:computername
    $OS_Titre.Content = $Computer_Mode
    $OS_Version.Content = "Windows 10 - $Release"
    $Mon_FARO.Content = "My user name: " + $env:username
    # $Graphisme.Content = "Graphic card: $Graphic_Card"
    # $Graphic_Card_details.Content = "$Graphic_Card"
    $Memory.Content = "Memory (RAM): $Memory_RAM GB"
    $Serial.Content = "Serial number: $Serial_Number"
}

#########################################################################
#                        INFORMATIONS FROM OVERVIEWPART                 #
#########################################################################

Launch_modal_progress

$Win32_LogicalDisk = Get-ciminstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }

function Get_Disk_Infos {
    $Total_size = [Math]::Round(($Win32_LogicalDisk.size / 1GB), 1)
    $Free_size = [Math]::Round(($Win32_LogicalDisk.Freespace / 1GB), 1)
    $Disk_information = $Disk_information + "(" + $Win32_LogicalDisk.deviceid + ") " + $Total_size + " GB (Total size) / " + + $Free_size + " GB (Free space)`n"
    $My_Disk_Info.Content = $Disk_information

    if ($Free_size -lt 1) {
        $Disk_Warning.Content = "(Low disk space)"
        $Disk_Warning.Foreground = "yellow"
        $Disk_Warning.FontWeight = "bold"

        $My_Disk_Info.Foreground = "yellow"
        $My_Disk_Info.FontWeight = "bold"
    }
    else {
        $Disk_Warning.Visibility = "Collapsed"
    }
}

if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
    $Get_MECM_Client_Version = (Get-CimInstance -Namespace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue).ClientVersion
}
else {
    $Get_MECM_Client_Version = (Get-WmiObject -Namespace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue).ClientVersion
}
if ($null -eq $Get_MECM_Client_Version) {
    $MECM_Client_Version_Block.Visibility = "Collapsed"
    $MECM_Client_Block.Visibility = "Collapsed"
    $MECM_Client_Version_Label.Content = "dd"
}
else {
    $MECM_Client_Version_Block.Visibility = "Visible"
    $MECM_Client_Block.Visibility = "Visible"
    $MECM_Client_Version_Label.Content = $Get_MECM_Client_Version
}


$Get_Support_Infos_Content = [xml](get-content "$current_folder\Config\Main_Config.xml")
$Reboot_Days_Alert = $Get_Support_Infos_Content.Config.Reboot_Days_Alert

$Last_boot = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
$Current_Date = Get-Date
$Diff_boot_time = $Current_Date - $Last_boot
$Last_Reboot.Content = "Last reboot: $Last_boot"
if (($Diff_boot_time.Days) -gt $Reboot_Days_Alert) {
    # if(($Diff_boot_time.Days)-gt 1)
    $Reboot_Alert_Block.Visibility = "Visible"
    $IsRebootRequired.Content = "Last reboot > $Reboot_Days_Alert days, please reboot your device when possible"
    $IsRebootRequired.FontWeight = "Bold"
    $IsRebootRequired.Foreground = "yellow"
}
else {
    $Last_Reboot_Alert.Content = ""
    $Reboot_Alert_Block.Visibility = "Collapsed"
}

Get_Overview_Infos
Get_Details_Infos
Get_Disk_Infos

# function Test-PendingReboot {
# if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
# if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
# try { 
# $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
# $status = $util.DetermineIfRebootPending()
# if(($status -ne $null)-and $status.RebootPending){
# return $true
# }
# } catch {}
# return $false
# }

if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
    $Drivers_Test = Get-CimInstance Win32_PNPEntity | Where-Object { $_.ConfigManagerErrorCode -gt 0 }
}
else {
    $Drivers_Test = Get-WmiObject Win32_PNPEntity | Where-Object { $_.ConfigManagerErrorCode -gt 0 }
}
$Search_Missing_Drivers = ($Drivers_Test | Where-Object { $_.ConfigManagerErrorCode -eq 28 }).Count
if ($Search_Missing_Drivers -gt 0) {
    $Missing_drivers.Content = "$Search_Missing_Drivers- drivers are missing"
    $Missing_drivers.Foreground = "Red"
}

# if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
# $Win32_Printer = Get-CimInstance -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
# }
# else {
# $Win32_Printer = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
# }
# $Printer.Content = $Win32_Printer.name

# if ($null -ne $Pending_Reboot) {
# #if ((Test-PendingReboot)-eq $true) {}
# if ($true) {
# $Pending_Reboot.Visibility = "Visible"
# }
# else {
# $Pending_Reboot.Visibility = "Collapsed"
# }
# } else {
# Write-Host "Error: `$Pending_Reboot not found!" -BackgroundColor Black -ForegroundColor Red
# }

#########################################################################
#                        CREATE MONITOR PART                            #
#########################################################################

# =================== StackPanel ======================================== 
function Create-StackPanel { 
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $StackPanelName,
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $StackPanelMarign,
        [Parameter(Position = 2, Mandatory = $true)]
        [string] $StackPanelOrientation,
        [Parameter(Position = 3)]
        [string] $StackPanelAlignment)

 
    $StackPanel = New-Object System.Windows.Controls.StackPanel
    $StackPanel.Name = $StackPanelName 
    $StackPanel.Orientation = $StackPanelOrientation
    $StackPanel.Margin = $StackPanelMarign
    $StackPanel.VerticalAlignment = "Stretch"
    if ($StackPanelMarign -eq "") { $StackPanel.HorizontalAlignment = "Center" }
    else { $StackPanel.HorizontalAlignment = $StackPanelAlignment } 

    return $StackPanel
}

# ======================== Label =======================================
function Create-Label { 
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $LabelName,
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $LabelMargin)
 
    $Label = New-Object System.Windows.Controls.Label
    $Label.Name = $LabelName 
    $Label.Margin = $LabelMargin
    $Label.FontSize = "16"
 
    return $Label
}

# ======================== Image =======================================
function Create-Image { 
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $ImageName,
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $ImageSize,
        [Parameter(Position = 2)]
        [string] $ImageMargin)
 
    $Image = New-Object System.Windows.Controls.Image
    $Image.Name = $RadioButtonName
    if ($ImageMargin -ne "") { $Image.Margin = $ImageMargin }
    $Image.Width = $ImageSize.Split(",")[0]
    $Image.Height = $ImageSize.Split(",")[1]
    $Image.HorizontalAlignment = "Center"
    $Image.VerticalAlignment = "Top" 
 
    return $Image
}

# ======================== Border =======================================
function Create-Border { 
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $BorderName,
        [Parameter(Position = 1, Mandatory = $true)]
        [string] $Margin,
        [Parameter(Position = 2)]
        [string] $Background)
 
    $Border = New-Object System.Windows.Controls.Border
    $Border.Name = $BorderName 
    if (($Background -ne "") -and ($Background -ne $null)) { $Border.Background = $Background }
    $Border.HorizontalAlignment = "Stretch"
    $Border.VerticalAlignment = "Stretch"
    $Border.BorderBrush = "WhiteSmoke"
    $Border.CornerRadius = 5
    $Border.BorderThickness = 1
    $Border.Margin = $Margin 
    return $Border
}

function Get_Monitor {
    if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $WMI1_WmiMonitorId = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorId
    }
    else {
        $WMI1_WmiMonitorId = Get-WmiObject -Namespace root\wmi -ClassName WmiMonitorId
    }
    $Global:AllMonitors = ForEach ($WMI1 in $WMI1_WmiMonitorId) {
        $WMI1_InstanceName = $WMI1.InstanceName
        $WMI1_FriendlyName = $WMI1.UserFriendlyName

        if ($WMI1_FriendlyName -gt 0) {
            $name = ($WMI1.UserFriendlyName -notmatch '^0$' | ForEach-Object { [char]$_ }) -join ""
        }
        else {
            $name = 'Internal screen'
        }

        if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
            $WMI2_WmiMonitorListedSupportedSourceModes = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorListedSupportedSourceModes
        }
        else {
            $WMI2_WmiMonitorListedSupportedSourceModes = Get-WmiObject -Namespace root\wmi -ClassName WmiMonitorListedSupportedSourceModes
        }
        
        foreach ($WMI2 in $WMI2_WmiMonitorListedSupportedSourceModes) {
            $WMI2_InstanceName = $WMI2.InstanceName
            if ($WMI1_InstanceName -eq $WMI2_InstanceName) {
                if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
                    $maxres = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorListedSupportedSourceModes | Select-Object -ExpandProperty MonitorSourceModes | Sort-Object -Property { $_.HorizontalActivePixels * $_.VerticalActivePixels } -Descending #| Select-Object -First 1
                }
                else {
                    $maxres = Get-WmiObject -Namespace root\wmi -ClassName WmiMonitorListedSupportedSourceModes | Select-Object -ExpandProperty MonitorSourceModes | Sort-Object -Property { $_.HorizontalActivePixels * $_.VerticalActivePixels } -Descending #| Select-Object -First 1
                }
            }
        }

        if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
            $WMI3_WmiMonitorBasicDisplayParams = Get-CimInstance -Namespace root\wmi -Class WmiMonitorBasicDisplayParams
        }
        else {
            $WMI3_WmiMonitorBasicDisplayParams = Get-WmiObject -Namespace root\wmi -Class WmiMonitorBasicDisplayParams
        }
        
        foreach ($WMI3 in $WMI3_WmiMonitorBasicDisplayParams) {
            $WMI3_InstanceName = $WMI3.InstanceName
            if ($WMI1_InstanceName -eq $WMI3_InstanceName) {
                $Monitor_Size = $WMI3 | Select-Object @{ Name = "Computer"; Expression = { $_.__SERVER } },
                @{N   = "Size";
                    E = { [System.Math]::Round(([System.Math]::Sqrt([System.Math]::Pow($_.MaxHorizontalImageSize, 2) + [System.Math]::Pow($_.MaxVerticalImageSize, 2)) / 2.54), 2) }
                }
            }
        }

        $Prop = @{
            'Name'   = $name
            'Serial' = (($WMI1.SerialNumberID -notmatch '^0$' | ForEach-Object { [char]$_ }) -join "")
            'Size'   = $Monitor_Size.size
        }
        New-Object -Type PSObject -Property $Prop
    }
}

# function Get_Graphic_Cards_Info {   
# if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
# $Get_Graphics_Infos = Get-CimInstance Win32_VideoController
# }
# else {
# $Get_Graphics_Infos = Get-WmiObject Win32_VideoController
# }
# $Graphic_Cards_Name = $Get_Graphics_Infos.Caption
# $Graphic_Cards_Driver_Version = $Get_Graphics_Infos.DriverVersion
# $Graphic_Card.Content = $Graphic_Cards_Name + "($Graphic_Cards_Driver_Version)"
# }

function Create_Monitor_Content {
    Get_Monitor
    $StackPanelmain = Create-StackPanel "StackPanelAllDisk" "0,0,0,0" "Horizontal" "Center" 

    foreach ($Monitor in $AllMonitors) {
        $StackPanelparent = [String]("StackPparent" + $Monitor.Serial)
        $StackforPartition = [String]("StackForPart" + $Monitor.Serial)
        $Borderdisk = [String]("BorderOf_" + $Monitor.Serial)
        $StackforPartition = Create-StackPanel $StackforPartition "0,0,0,0" "Horizontal" "Center"
        $StackPanelparent = Create-StackPanel $StackPanelparent "0,0,0,0" "Vertical" "Center"# inside the block
        $Borderdisk = Create-Border $Borderdisk "10,30,0,0"
        $Borderdisk.BorderThickness = "0"

        #======================= disk_n ==================================
        $Titre_Label = [String]("Monitor_" + $Monitor.Serial )
        $Monitor_Pic = [String]("Monitor_" + $Monitor.Serial + "_ico" )
        $ChildSizeInfo = [String]("Monitor_" + $Monitor.Serial + "_size" )
        $Carte_LabelInfo = [String]("Monitor_" + $Monitor.Serial + "_size" )
        $Serial_LabelInfo = [String]("Monitor_" + $Monitor.Serial + "_size" )
        $StackPaneldisk = [String]("Monitor_" + $Monitor.Serial + "_stackP" )

        $StackPaneldisk = Create-StackPanel $StackPaneldisk "0,0,0,0" "Vertical" "Center"
        $DiskManagIco = Create-Image $Monitor_Pic "100,90" "5,5,0,0"
        $Titre_Label = Create-Label $Titre_Label "5,0,0,0" #Disk Id
        $Resolution_Label = Create-Label $ChildSizeInfo "5,0,0,0"
        $Carte_Label = Create-Label $Carte_LabelInfo "5,0,0,0"
        $Serial_Label = Create-Label $Serial_LabelInfo "5,0,0,0"

        $DiskManagIco.Source = "$Current_Folder\images\monitor.png" 
        $Titre_Label.Content = $Monitor.Name
        $Titre_Label.FontWeight = "Bold"
        $Titre_Label.FontSize = "20"

        $Monitor_Size = $Monitor.size
        $Monitor_Size = [math]::Round($Monitor_Size)
        $Resolution_Label.Content = "Size: " + $Monitor_Size + " Inch" 
        $Resolution_Label.FontSize = "14"
        # $Carte_Label.Content= $Graphic_Card
        $Carte_Label.FontSize = "14" 

        $Serial_Label.Content = "Serial: " + $Monitor.serial 
        $Serial_Label.FontSize = "14" 
 
        $StackPaneldisk.Children.Add($DiskManagIco)
        $StackPaneldisk.Children.Add($Titre_Label)
        $StackPaneldisk.Children.Add($Carte_Label)
        $StackPaneldisk.Children.Add($Serial_Label)
        $StackPaneldisk.Children.Add($Resolution_Label)

        $StackPanelparent.Width = 200
        $StackPanelparent.Height = 260
        $StackPanelparent.Children.Add($StackPaneldisk)

        if ($my_theme -eq "BaseDark") {
            $Titre_Label.Foreground = "black"
            $Carte_Label.Foreground = "black"
            $Serial_Label.Foreground = "black"
            $Resolution_Label.Foreground = "black"
        }
        else {
            $Titre_Label.Foreground = "White"
            $Resolution_Label.Foreground = "White"
            $Carte_Label.Foreground = "White"
            $Serial_Label.Foreground = "White"
        }

        $StackforPartition.Children.Add($StackPanelparent)
        $Borderdisk.Child = $StackforPartition
        $StackPanelmain.Children.Add($Borderdisk)
    }
    $MonitorList.Children.Add($StackPanelmain)
}

#########################################################################
#                        CREATE MONITOR PART                            #
#########################################################################

#########################################################################
#                        CREATE STORAGE DISK PART                       #
#########################################################################

function Check_Folder_Size {
    param(
        $Folder_Path
    )

    if (Test-Path $Folder_Path) {
        try {
            $Get_Folder_Size = (Get-ChildItem $Folder_Path -Recurse -File -ErrorAction SilentlyContinue -ErrorVariable err | Measure-Object -Property Length -Sum).Sum
        }
        catch {
            "KO ==> Issue while checking size of $Folder"
            write-host ""
            write-host "################################################# ISSUE REPORTED #################################################"
            $_.Exception.ToString()
            write-host "################################################# ISSUE REPORTED #################################################"
            $Global:LastExitCode = 1
        }

        if ($null -eq $Get_Folder_Size) {
            $folderSizeOutput = "0"
        }
        elseif ( $Get_Folder_Size -lt 1KB ) { 
            $folderSizeOutput = "$("{0:N2}" -f $Get_Folder_Size)B" 
        }
        elseif ( $Get_Folder_Size -lt 1MB ) { 
            $folderSizeOutput = "$("{0:N2}" -f ($Get_Folder_Size / 1KB)) KB" 
        }
        elseif ( $Get_Folder_Size -lt 1GB ) { 
            $folderSizeOutput = "$("{0:N2}" -f ($Get_Folder_Size / 1MB)) MB" 
        }
        elseif ( $Get_Folder_Size -lt 1TB ) { 
            $folderSizeOutput = "$("{0:N2}" -f ($Get_Folder_Size / 1GB)) GB" 
        }
        elseif ( $Get_Folder_Size -lt 1PB ) { 
            $folderSizeOutput = "$("{0:N2}" -f ($Get_Folder_Size / 1TB)) TB" 
        }
        elseif ( $Get_Folder_Size -ge 1PB ) { 
            $folderSizeOutput = "$("{0:N2}" -f ($Get_Folder_Size / 1PB)) PB" 
        }

        $Global:Full_Folder_Size = New-Object -TypeName psobject
        $Full_Folder_Size | Add-Member -MemberType NoteProperty -Name Size_Formated -Value $folderSizeOutput
        $Full_Folder_Size | Add-Member -MemberType NoteProperty -Name Size_Normal -Value $Get_Folder_Size
    }
    else {
        Write-Host "Can not find the folder $Folder_Path"
    }
    return $Full_Folder_Size
}

# $OneDrive_Commercial_Folder = $env:OneDriveCommercial

# $User_Profile_Folder = $env:USERPROFILE

$Desktop_Path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders").Desktop
$Documents_Path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders").Personal
$Music_Path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders")."My Music"
$Download_Path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders")."{374DE290-123F-4565-9164-39C4925E467B}"

# $documents_Size = (Check_Folder_Size -Folder_Path "$User_Profile_Folder\Documents")
$documents_Size = (Check_Folder_Size -Folder_Path $Documents_Path)
$documents_Size_Normal = $documents_Size.Size_Normal
$documents_Size_Formated = $documents_Size.Size_Formated

# $download_size = (Check_Folder_Size -Folder_Path "$User_Profile_Folder\Downloads")
$download_size = (Check_Folder_Size -Folder_Path $Download_Path)
$download_size_Normal = $download_size.Size_Normal
$download_size_Formated = $download_size.Size_Formated

# $desktop_size = (Check_Folder_Size -Folder_Path "$User_Profile_Folder\Desktop")
$desktop_size = (Check_Folder_Size -Folder_Path $Desktop_Path)
$desktop_size_Normal = $desktop_size.Size_Normal
$desktop_size_Formated = $desktop_size.Size_Formated

# $music_size = (Check_Folder_Size -Folder_Path "$User_Profile_Folder\Music")
$music_size = (Check_Folder_Size -Folder_Path $Music_Path)
$music_size_Normal = $music_size.Size_Normal
$music_size_Formated = $music_size.Size_Formated

$Total_size = [Math]::Round(($Win32_LogicalDisk.size / 1GB), 1)
$Total_size_full = $Win32_LogicalDisk.size
$Free_Space = $Win32_LogicalDisk.FreeSpace

$Free_Space_Formated = "$("{0:N2}" -f ($Free_Space / 1GB))GB" 

[int]$Doc_Used_Size = '{0:N0}' -f (($documents_Size_Normal / $Total_size_full * 100), 1)
[int]$download_Used_Size = '{0:N0}' -f (($download_size_Normal / $Total_size_full * 100), 1)
[int]$music_Used_Size = '{0:N0}' -f (($music_size_Normal / $Total_size_full * 100), 1)
[int]$desktop_Used_Size = '{0:N0}' -f (($desktop_size_Normal / $Total_size_full * 100), 1)
[int]$Free_Space_Used_Size = '{0:N0}' -f (($Free_Space / $Total_size_full * 100), 1)

# 1043310224

$Main_bar_Value = $Doc_Used_Size + $Free_Space_Used_Size + $desktop_Used_Size + $download_Used_Size
$value_to_mulitply = 500 / $Main_bar_Value

$MyDocs.Width = $Doc_Used_Size * $value_to_mulitply
$Label_Docs = New-Object system.windows.controls.label
$Label_Docs.Content = $Doc_Used_Size 
$Label_Docs.Foreground = "white"
$Label_Docs.HorizontalAlignment = "center"
$Label_Docs.VerticalAlignment = "center"
$MyDocs.Children.Add($Label_Docs)
$MyDocs.Background = "#2195F2"

$Downloads.Width = $download_Used_Size * $value_to_mulitply
$Label_Download = New-Object system.windows.controls.label
$Label_Download.Content = $download_Used_Size 
$Label_Download.Foreground = "white"
$Label_Download.HorizontalAlignment = "center"
$Label_Download.VerticalAlignment = "center"
$Downloads.Children.Add($Label_Download)
$Downloads.Background = "#607D8A"

$MyDesktop.Width = $desktop_Used_Size * $value_to_mulitply
$Label_Desktop = New-Object system.windows.controls.label
$Label_Desktop.Content = $desktop_Used_Size 
$Label_Desktop.Foreground = "white"
$Label_Desktop.HorizontalAlignment = "center"
$Label_Desktop.VerticalAlignment = "center"
$MyDesktop.Children.Add($Label_Desktop)
$MyDesktop.Background = "#F34336"

$Free.Width = $Free_Space_Used_Size * $value_to_mulitply
$Label_Free = New-Object system.windows.controls.label
$Label_Free.Content = $Free_Space_Used_Size 
$Label_Free.Foreground = "white"
$Label_Free.HorizontalAlignment = "center"
$Label_Free.VerticalAlignment = "center"
$Free.Children.Add($Label_Free)
$Free.Background = "#00BBD3"

$Legend_FreeSpace = "Free disk space ($Free_Space_Formated)"

if ($Desktop_Path -like "*onedrive*") {
    # $Legend_MyDesktop = "Desktop ($desktop_size_Formated)(Redirected to OneDrive)"
    $Legend_MyDesktop = "Desktop (OneDrive)($desktop_size_Formated)"
}
elseif ($Desktop_Path -like "*\\*") {
    $Legend_MyDesktop = "Desktop (DFS)($desktop_size_Formated)"
}
else {
    $Legend_MyDesktop = "Desktop ($desktop_size_Formated)"
}

if ($Documents_Path -like "*onedrive*") {
    $Legend_MyDocuments = "Documents (OneDrive)($documents_Size_Formated)"
}
elseif ($Documents_Path -like "*\\*") {
    $Legend_MyDocuments = "Documents (DFS)($documents_Size_Formated)"
}
else {
    $Legend_MyDocuments = "Documents ($documents_Size_Formated)"
}

if ($Download_Path -like "*onedrive*") {
    $Legend_Download = "Download (OneDrive)($download_size_Formated)"
}
elseif ($Download_Path -like "*\\*") {
    $Legend_Download = "Download (DFS)($download_size_Formated)"
}
else {
    $Legend_Download = "Download ($download_size_Formated)"
}

if ($Music_Path -like "*onedrive*") {
    $Legend_MyMusic = "Music (OneDrive)($music_size_Formated)"
}
elseif ($Music_Path -like "*\\*") {
    $Legend_MyMusic = "Music (DFS)($music_size_Formated)"
}
else {
    $Legend_MyMusic = "Music ($music_size_Formated)"
}

$MyDocs.ToolTip = $Legend_MyDocuments
$Downloads.ToolTip = $Legend_Download
$MyDesktop.ToolTip = $Legend_MyDesktop
$Music.ToolTip = $Legend_MyMusic
$Free.ToolTip = $Legend_FreeSpace

$Legend_Border_MyDesktop.Background = "#F34336"
$Legend_Label_MyDesktop.Content = $Legend_MyDesktop

$Legend_Border_MyDocs.Background = "#2195F2"
$Legend_Label_MyDocs.Content = $Legend_MyDocuments

$Legend_Border_Downloads.Background = "#607D8A"
$Legend_Label_Downloads.Content = $Legend_Download

$Legend_Border_Music.Background = "#FEC007"
$Legend_Label_Music.Content = $Legend_MyMusic

$Legend_Border_Free.Background = "#00BBD3"
$Legend_Label_Free.Content = $Legend_FreeSpace

$List_Large_Files.Add_MouseLeftButtonDown(
    {
        Start-Process -WindowStyle Hidden powershell.exe "$current_folder\Actions_scripts\List_Large_Files.ps1" 
    }
)

#########################################################################
#                        CREATE STORAGE DISK PART                       #
#########################################################################

Close_modal_progress

$refresh_monitor.Add_Click(
    {
        $MonitorList.Children.Clear()
        Get_Monitor
        Create_Monitor_Content
    }
)

function Show_Chart_Stockage {
    $DoughnutCollection = [LiveCharts.SeriesCollection]::new()

    $chartvalue1 = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservableValue]]::new()
    $pieSeries = [LiveCharts.Wpf.PieSeries]::new()

    if ($Doc_Used_Size -gt 0) {
        $chartvalue1.Add([LiveCharts.Defaults.ObservableValue]::new($Doc_Used_Size))
    }
    $pieSeries.Values = $chartvalue1
    $pieSeries.Title = $Legend_MyDocuments
    $pieSeries.DataLabels = $true
    $DoughnutCollection.Add($pieSeries)
    Write-Verbose "PIE/CHART1: $chartvalue1, Legend: $Legend_MyDocuments, DocsUsed: $Doc_Used_Size"
    
    $chartvalue2 = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservableValue]]::new()
    $pieSeries = [LiveCharts.Wpf.PieSeries]::new()
    if ($desktop_Used_Size -gt 0) {
        $chartvalue2.Add([LiveCharts.Defaults.ObservableValue]::new($desktop_Used_Size))
    }
    $pieSeries.Values = $chartvalue2
    $pieSeries.Title = $Legend_MyDesktop
    $pieSeries.DataLabels = $true
    $DoughnutCollection.Add($pieSeries)
    Write-Verbose "PIE/CHART2: $chartvalue2, Legend: $Legend_MyDesktop, DesktopUsed: $desktop_Used_Size"

    $chartvalue3 = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservableValue]]::new()
    $pieSeries = [LiveCharts.Wpf.PieSeries]::new()
    if ($music_Used_Size -gt 0) {
        $chartvalue3.Add([LiveCharts.Defaults.ObservableValue]::new($music_Used_Size))
    }
    $pieSeries.Values = $chartvalue3
    $pieSeries.Title = $Legend_MyMusic
    $pieSeries.DataLabels = $true
    $DoughnutCollection.Add($pieSeries)
    Write-Verbose "PIE/CHART3: $chartvalue3, Legend: $Legend_MyMusic, MusicUsed: $music_Used_Size"

    $chartvalue4 = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservableValue]]::new()
    $pieSeries = [LiveCharts.Wpf.PieSeries]::new()
    if ($download_Used_Size -gt 0) {
        $chartvalue4.Add([LiveCharts.Defaults.ObservableValue]::new($download_Used_Size))
    }
    $pieSeries.Values = $chartvalue4
    $pieSeries.Title = $Legend_Download
    $pieSeries.DataLabels = $true
    $DoughnutCollection.Add($pieSeries)
    Write-Verbose "PIE/CHART4: $chartvalue3, Legend: $Legend_Download, DownloadUsed: $download_Used_Size"

    $chartvalue5 = [LiveCharts.ChartValues[LiveCharts.Defaults.ObservableValue]]::new()
    $pieSeries = [LiveCharts.Wpf.PieSeries]::new()
    if ($Free_Space_Used_Size -gt 0) {
        $chartvalue5.Add([LiveCharts.Defaults.ObservableValue]::new($Free_Space_Used_Size))
    }
    $pieSeries.Values = $chartvalue5
    $pieSeries.Title = $Legend_FreeSpace
    $pieSeries.DataLabels = $true
    $DoughnutCollection.Add($pieSeries)
    Write-Verbose "PIE/CHART5: $chartvalue5, Legend: $Legend_FreeSpace, FreeUsed: $Free_Space_Used_Size"

    $Doughnut.Series = $DoughnutCollection
}

$refresh_monitor.Visibility = "Collapsed"

$Tab_Control.Add_SelectionChanged(
    {
        if (($Tab_Control.SelectedItem.Header -eq "Overview") -or ($Tab_Control.SelectedItem.Header -eq "Support")) {
            $refresh_monitor.Visibility = "Collapsed"
        }
        if ($Tab_Control.SelectedItem.Header -eq "Storage") {
            Show_Chart_Stockage
            $refresh_monitor.Visibility = "Collapsed"
        }
        elseif ($Tab_Control.SelectedItem.Header -eq "Monitors") {
            $refresh_monitor.Visibility = "Visible"
            $MonitorList.Children.Clear()
            Get_Monitor
            Create_Monitor_Content
        }
    }
)
    
$Get_Support_Infos_Content = [xml](get-content "$current_folder\Config\Support.xml")
$Website_Link = $Get_Support_Infos_Content.Infos.Website_Link
$Chat_Link = $Get_Support_Infos_Content.Infos.Chat_Link
$Yammer_Link = $Get_Support_Infos_Content.Infos.Yammer_Link
$Phone_Number = $Get_Support_Infos_Content.Infos.Phone_Number
$Our_Mail = $Get_Support_Infos_Content.Infos.Mail
$Our_Phone.Content = $Phone_Number

$Get_Support_Infos_Content = [xml](get-content "$current_folder\Config\Main_Config.xml")
$Main_Color = $Get_Support_Infos_Content.Config.Main_Color
$Overview_Logo = $Get_Support_Infos_Content.Config.Overview_Logo
$Main_Language = $Get_Support_Infos_Content.Config.Main_Language
$Display_Send_Logs = $Get_Support_Infos_Content.Config.Display_Send_Logs

$Tool_Logo.Source = "$current_folder\images\$Overview_Logo"

$Theme = [MahApps.Metro.ThemeManager]::DetectAppStyle($Window)
[MahApps.Metro.ThemeManager]::ChangeAppStyle($Window, [MahApps.Metro.ThemeManager]::GetAccent("$Main_Color"), $Theme.Item1);

$Website.Add_PreviewMouseDown(
    {
        [system.Diagnostics.Process]::start("$Website")
    }
)

$Chat.Add_PreviewMouseDown(
    {
        [system.Diagnostics.Process]::start("$Chat_Link")
    }
)

$Mail.Add_PreviewMouseDown(
    {
        $Our_Mail = "dummy@example.com"
        $Computer_Name = $env:COMPUTERNAME
        $User_Name = $env:USERNAME
        $Mail_Object = "Issue from user $User_Name on device $Computer_Name"
        Start-Process "mailto:dummy@domain.tld?Subject=$Mail_Object&Cc=dhub02@domain.tld&Body=$Mail_Object"
    }
)

$Yammer.Add_PreviewMouseDown(
    {
        [system.Diagnostics.Process]::start("$Yammer_Link")
    }
)

# TODO: Look at XAML. SendLogs not ava.?
if ($null -eq $Send_Logs) {
    Write-Host "Error: `$Send_Logs not found!" -BackgroundColor Black -ForegroundColor Red
}
else {
    $Send_Logs.Add_PreviewMouseDown(
        {
            [system.Diagnostics.Process]::start("https://www.example.com")
        }
    )
}

if ($Website_Link -ne "") {
    $Website_Block.Visibility = "Visible"
}
else {
    $Website_Block.Visibility = "Collapsed"
}

if ($Yammer_Link -ne "") {
    $Yammer_Block.Visibility = "Visible"
}
else {
    $Yammer_Block.Visibility = "Collapsed"
}

if ($Chat_Link -ne "") {
    $Chat_Block.Visibility = "Visible"
}
else {
    $Chat_Block.Visibility = "Collapsed"
}

if (($Chat_Link -eq "") -and ($Yammer_Link -eq "") -and ($Website_Link -eq "")) {
    $Issue_Block.Margin = "20,80,0,0"
}
elseif (($Chat_Link -eq "") -and ($Yammer_Link -eq "")) {
    $Issue_Block.Margin = "20,50,0,0"
}
else {
    $Issue_Block.Margin = "20,10,0,0"
}

if ($Window.ShowDialog()) {
    Write-Host "Successfully processed dialog."
}
else {
    Write-Host "Window/Dialog not processed successfully."
}