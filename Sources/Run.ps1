$ApplicationPath = "$env:ProgramData\GRT_AboutMyDevice"
if (!(Test-Path -Path $ApplicationPath)) {
    Write-Host "Path '$ApplicationPath' could not found!" -BackgroundColor Black -ForegroundColor Red
    return 
}

Set-Location "$ApplicationPath"
Start-Process -WindowStyle Hidden powershell.exe "$ApplicationPath\About_this_computer.ps1"