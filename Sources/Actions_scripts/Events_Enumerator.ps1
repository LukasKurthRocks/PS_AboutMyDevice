
# ***********************************************************************
# Variables initialization
# ***********************************************************************
$Temp = $env:temp
$ProgData = $env:PROGRAMDATA
$All_System_Error = Get-EventLog System | Where-Object { $_.EntryType -eq "Error" } | Select-Object timegenerated, source, eventid, message
$All_Apps_Error = Get-EventLog Application | Where-Object { $_.EntryType -eq "Error" } | Select-Object timegenerated, source, eventid, message

$Date = Get-Date
# $HTML_Events = "$Temp\OEM_Support\Events_List.html"
$HTML_Events = "$Temp\Events_List.html"
# $CSS_File = "$temp\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export
$CSS_File = "$ProgData\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export

# *************************************************************************************************

$Title = "<p><span class=titre_list>Last applications and system errors on $env:COMPUTERNAME</span><br><span class=subtitle>This document has been updated on $Date</span></p><br>"

$System_Events = "<p class=New_object>Last 10 system errors</p>"
$System_Events_b = $All_System_Error | Select-Object -first 10 | ForEach-Object { New-Object psobject -Property @{
		Date     = $_."timegenerated"
		Source   = $_."source"
		Event_ID = $_."eventid"
		Issue    = $_."message"
	}
} | Select-Object Date, Source, Event_ID, Issue | ConvertTo-HTML -Fragment

$System_Events = $System_Events + $System_Events_b

$Apps_Events = "<p class=New_object>Last 10 application errors</p>"
$Apps_Events_b = $All_Apps_Error | Select-Object -first 10 | ForEach-Object { New-Object psobject -Property @{
		Date     = $_."timegenerated"
		Source   = $_."source"
		Event_ID = $_."eventid"
		Issue    = $_."message"
	}
} | Select-Object Date, Source, Event_ID, Issue | ConvertTo-HTML -Fragment

$Apps_Events = $Apps_Events + $Apps_Events_b

ConvertTo-HTML -Body " $Title<br>$System_Events<br><br>$Apps_Events" -CssUri $CSS_File | 
Out-File -Encoding ASCII $HTML_Events