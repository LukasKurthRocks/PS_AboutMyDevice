# ***********************************************************************
# Variables initialization
# ***********************************************************************
$Date = Get-Date
$HTML_Drivers = "$env:TEMP\Drivers_List.html"
# $HTML_Drivers = "$env:TEMP\OEM_Support\Drivers_List.html"
$Global:Current_Folder = (Get-Location).Path
# $CSS_File = "$env:TEMP\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export
$CSS_File = "$env:PROGRAMDATA\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export

$Title = "<p><span class=titre_list>Drivers list on $env:COMPUTERNAME</span><br><span class=subtitle>This document has been updated on $Date</span></p><br>"

$Drivers_list_b = Get-WmiObject Win32_PnPSignedDriver | Select-Object devicename, manufacturer, driverversion, infname, IsSigned |
Where-Object { $_.devicename -ne $null -and $_.infname -ne $null } | Sort-Object devicename -Unique | ConvertTo-HTML -Fragment

$Drivers_list = $Drivers_list + $Drivers_list_b

ConvertTo-HTML -Body " $Title<br>$Drivers_list" -CssUri $CSS_File | Out-File -Encoding ASCII $HTML_Drivers