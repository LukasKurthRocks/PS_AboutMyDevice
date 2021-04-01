# About my device

Ich möchte den Code so umstellen, dass er für mich am besten wartbar ist und ich ihn für die Arbeit verwenden lann.\
Erster Schritt: Get-WMI* ist veraltet und sollte durch Get-CIM* ausgetauscht werden. Mal schauen ob es dann auch unter PowerShell 7 läuft.

## TODO
- [X] WMI* durch CIM* tauschen (Müsste ich mit durch sein)
- [ ] Details > IPAddress zeigt eine Addresse an, mit VMWare und Hyper-V hat man allerdings mehrere Netzwerkkarten.
Auswahl oder alle Addressen in Tooltip anzeigen? Eventuell mit Kartennamen!?
- [ ] Admin Menu (password if not admin) => Displaying Admin Stuff (bigger window?)
  - Something like: https://www.systanddeploy.com/2019/12/task-sequence-password-protect-gui-for.html
  ![ALT](https://1.bp.blogspot.com/-XKK1lFaRbR4/XeGK54cDpII/AAAAAAAAMBc/1tZonS6NhPwiH-qvMXJsHnXhyLSxI9pKQCLcBGAsYHQ/s400/Untitled%2BProject.gif)
  ![ALT](https://raw.githubusercontent.com/damienvanrobaeys/TS_AD_Protect/master/in_action.gif)
- [ ] PowerShell v7 testen
- [ ] Mirror für spezifische Arbeitsdaten