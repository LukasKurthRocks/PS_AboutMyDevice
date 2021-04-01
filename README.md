# About my device

Ich möchte den Code so umstellen, dass er für mich am besten wartbar ist und ich ihn für die Arbeit verwenden lann.\
Erster Schritt: Get-WMI* ist veraltet und sollte durch Get-CIM* ausgetauscht werden. Mal schauen ob es dann auch unter PowerShell 7 läuft.

## TODO
- [X] WMI* durch CIM* tauschen (Müsste ich mit durch sein)
- [ ] Details > IPAddress zeigt eine Addresse an, mit VMWare und Hyper-V hat man allerdings mehrere Netzwerkkarten.
Auswahl oder alle Addressen in Tooltip anzeigen? Eventuell mit Kartennamen!?
- [ ] PowerShell v7 testen
- [ ] Mirror für spezifische Arbeitsdaten