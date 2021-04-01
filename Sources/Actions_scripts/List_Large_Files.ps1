$Get_Large_Files = Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue | Sort-Object -Descending -Property Length | Select-Object -First 10 Name, Length, FullName
$Get_Large_Files | Out-File "$env:Temp\Large_Files.txt"
Invoke-Item "$env:Temp\Large_Files.txt"