# About my device

Ich möchte den Code so umstellen, dass er für mich am besten wartbar ist und ich ihn für die Arbeit verwenden lann.\
Erster Schritt: Get-WMI* ist veraltet und sollte durch Get-CIM* ausgetauscht werden. Mal schauen ob es dann auch unter PowerShell 7 läuft.

## TODO
- [ ] Details > IPAddress zeigt eine Addresse an, mit VMWare und Hyper-V hat man allerdings mehrere Netzwerkkarten.
Auswahl oder alle Addressen in Tooltip anzeigen? Eventuell mit Kartennamen!?
- [ ] Admin Menu (password if not admin) => Displaying Admin Stuff (bigger window?)
  - [ ] Replace ActiveDirectory with ADSearcher!?
- [ ] PowerShell v7 testen
- [ ] Mirror für eine Version die für die Arbeit abgestimmt ist
- [ ] So wie ich das sehe, gibt es hier viel verschenktes Potential!

## Done
- [X] WMI* durch CIM* tauschen (Müsste ich mit durch sein)
- [X] Grundfunktion für Admin+PW im neuen Interface hinzufügen. (Werde das noch anpassen, aber GUI ist da. C# Grundfunktionen gehen auch, aber ich brauche das vor allem in PowerShell!)
  - [X] https://www.systanddeploy.com/2019/12/task-sequence-password-protect-gui-for.html
  - [X] https://github.com/damienvanrobaeys/TS_AD_Protect\
