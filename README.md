# About my device

Ich möchte den Code so umstellen, dass er für mich am besten wartbar ist und ich ihn für die Arbeit verwenden lann.\
Erster Schritt: Get-WMI* ist veraltet und sollte durch Get-CIM* ausgetauscht werden. Mal schauen ob es dann auch unter PowerShell 7 läuft.

## TODO
- [ ] Details > IPAddress zeigt eine Addresse an, mit VMWare und Hyper-V hat man allerdings mehrere Netzwerkkarten.
Auswahl oder alle Addressen in Tooltip anzeigen? Eventuell mit Kartennamen!?
- [ ] Admin Menu (password if not admin) => Displaying Admin Stuff (bigger window?)
  - [ ] Replace ActiveDirectory with ADSearcher!?
  - [ ] Bloatware und Konfigurations-Zeug? => WinRM, Remote, OneDrive, Cortana, PeopleBar => Siehe TaskSequence Zeug!?
- [ ] PowerShell v7 testen
- [ ] Mirror für eine Version die für die Arbeit abgestimmt ist
- [ ] So wie ich das sehe, gibt es hier viel verschenktes Potential!
- [ ] Fehlendes
  - [ ] Softwarecenter Starten?
  - [ ] Verschiedene Sprachen: Fr, De, En?
- [ ] Monitore sind bei 3+ etwas verschoben!!
- [ ] TeamViewer Status? (Läuft, Läuft nicht, Version, PW?, ID?)
  - [ ] Alternativ AnyDesk?
- [ ] Sprachinformationen (System + User)