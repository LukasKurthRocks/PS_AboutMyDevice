# ***********************************************************************
# Variables initialization
# ***********************************************************************
$HotfixCount = (Get-WmiObject Win32_QuickFixEngineering | Measure-Object).Count
$Date = Get-Date
$HTML_Hotfix = "$env:temp\hotfixes.html"
$CSS_File = "$env:ProgramData\OEM_Support\Actions_Scripts\HTML_Export_CSS.css" # CSS for HTML Export

# *************************************************************************************************

# $Title = "<p><span class=titre_list>Last applications and system errors on $env:COMPUTERNAME</span><br><span class=subtitle>This document has been updated on $Date</span></p><br>"
$Title = "<p><span class=titre_list>Hotfix list on $env:COMPUTERNAME</span><br><span class=subtitle>$HotfixCount are installed on $Date</span></p><br>"

if (Get-Command -Name "Get-CimInstance" -ErrorAction SilentlyContinue) {
    $Hotfix_list = Get-CimInstance win32_quickfixengineering | Select-Object hotfixid, Description, Caption, InstalledOn | Sort-Object InstalledOn | ConvertTo-HTML -Fragment
}
else {
    $Hotfix_list = Get-WmiObject win32_quickfixengineering | Select-Object hotfixid, Description, Caption, InstalledOn | Sort-Object InstalledOn | ConvertTo-HTML -Fragment
}

# $Hotfix_list = $Hotfix_list + $Hotfix_list_b

ConvertTo-HTML -Body " $Title<br>$Hotfix_list" -CSSUri $CSS_File | Out-File -Encoding ASCII $HTML_Hotfix