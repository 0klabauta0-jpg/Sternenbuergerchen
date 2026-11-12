# AP6 RuntimeSelection — Codeabschluss, Gameplayprüfung verlegt

Basis ad2924beb, weiterhin isolierter unintegrierter Taskbranch. Keine Main-,
Produktionskarten-, EXE- oder Performancefreigabe.

Die drei historischen tatsächlichen Läufe im ZIP sind vollständig mit Original-
Logs, Quellenhashes und Isolations-/Profilguards erhalten:

1. 6/7: IDvertauschung, unvollständiges Retirement, alte Commands, fehlende
   Leaderbereinigung und fehlende direkte Rootadmission.
2. 13/0: kleiner Basisslice nach Personenabgleich und vorbereiteten Modellen.
3. 13/3: zusätzliche konkrete Repros für zu frühe Identitysetter-Signale,
   gepufferten Request nach Rootersatz und Folgewrites nach Registryersatz.

Der letzte Code schließt diese drei Befunde: Identitysetter emittieren während
der vorbereiteten Modellphase nicht; guarded Finalize publiziert nach allen
Actor-/Known-/Registry-/Leaderänderungen das vorhandene identity_changed und
Runtimefeedback. Requests tragen bereits bei Aufnahme konkrete Owner-, Kontext-,
Registry-, Leader- und Actorlebensbindungen. Commitreceipt und alle Folgewrites
prüfen dieselben Besitzer. Private Bindungen bleiben außerhalb portabler Daten.

Nach neuer direkter Nutzersteuerung wurden keine weiteren Gameplay-, Randfall-
oder Reviewrunden gestartet. `syntax_only.log` und `manifest.json` belegen nur
den erfolgreichen GDScript-Parse der tatsächlichen neuen Closure. **13/0 ist keine
Freigabe des späteren Codes und 13/3 keine nachträglich als grün erklärte Probe.**
Die Gameplaynachprüfung der drei Fixes und die übrige gemeinsame Abnahme folgen
gebündelt nach den AP7-/AP8-Codeblöcken. Keine Performanceaussage.

Bestehende IDs behalten Actor, Gesundheit, Auftrag und Feld, einschließlich
staged Personen. Nur entfernte/umbenannte Slots verlieren alte Arbeit.
preserve_existing=false bedeutet Gearrefresh, keinen Szenario-/Präsenzreset.
UnitRegistry mutiert ausschließlich Lookupbindungen; RuntimeLeader ergänzt
exaktes Remove und Entityleser. Gesundheitsmodelle und medizinische Bodies
bleiben unverändert. Der vorhandene FOB-Configbau wird gemeinsam verwendet;
normale Identitätspublikation bleibt standardmäßig unmittelbar wirksam.

Für den getrennten Parent-Netzblock ist der optionale Hook
`refresh_multiplayer_replica_presence()` nach vollständigem initialem Clientsetup
und Selectiontail vorgesehen. Er betrifft ausschließlich Clientpräsentation;
hier existiert noch kein neuer Netzsender/-receiver. Bootstrap-/Checkpoint- und
Netzintegration erfolgen als AP7, anschließend AP8 und gebündelte Prüfungen.
