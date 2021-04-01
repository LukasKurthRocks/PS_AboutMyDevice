# ***********************************************************************
# Variables initialization
# ***********************************************************************
$Date = Get-Date
$HTML_Services = "$env:Temp\Services_List.html"
$CSS_File = "$env:PROGRAMDATA\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export

$Title = "<p><span class=titre_list>Drivers list on $env:COMPUTERNAME</span><br><span class=subtitle>This document has been updated on $Date</span></p><br>"

$services_list_b = Get-wmiobject win32_service |
Select-Object Name, Caption, State, Startmode | ConvertTo-HTML -Fragment

$colorTagTable = @{
	Stopped = ' class="stopped">Stopped<'
	Running = ' class="running">Running<'
}

$services_list = $services_list + $services_list_b
 
$colorTagTable.Keys | ForEach-Object { $services_list = $services_list -Replace ">$_<", ($colorTagTable.$_) }

ConvertTo-HTML -body " $Title<br>$services_list" -CSSUri $CSS_File | 
Out-File -Encoding ASCII $HTML_Services