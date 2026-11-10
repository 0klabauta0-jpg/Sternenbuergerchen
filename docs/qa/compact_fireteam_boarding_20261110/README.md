# Kompakte Truppkarte, Aufsitzen und Basis-Untermenü — 10.11.2026
Basis: Main 1e3cca237, Taskbranch task/compact-fireteam-boarding-20261110.

Gemeinsame ausgewählte Truppkarte statt doppeltem FT1. Quadratische Porträts
64/58/53 statt96/88/80, kleinere Buttons; andere Teams bleiben auswählbar.
Aufsitzen am Trupp führt echten Rückweg und vorhandene Boardingeffekte aus,
ohne Abheben. Doppelklick nach Teamwechsel öffnet die richtige Person; Routing
wird anhand tatsächlicher Team-/Unit-ID umgebunden, Controls bleiben gecacht.

Basisverwaltung liegt als Hover-/Fokus-Untermenü unter Basis erkunden.
Karte frei; Auswahl und Verlassen klappen zu. Datenterminal erklärt auch
fehlgeschlagene und bereits abgeschlossene Aufträge.

## Prüfungen
- Kompakte Karte nativ D3D12:41/0, Enginefehler0. Logische Viewports1280/1920/3440
  auf verborgenem1280×720-Enginehost, keine drei physischen Monitorauflösungen.
- Vollständiger echter erster Kampagnenausflug:84/0. Dualrolle Pilot in FT1,
  Aufsitzen per tatsächlichem Button, Absetzen, echte Datensicherung, Heimreise,
  tatsächliches Schlafen, erhaltener pending_upload-Chip, sichtbarer Uploadbutton,
  Upload, einmalige Belohnung, Herstellung und Checkpoint. Headless, Zeitfaktor4.
- Basis-Untermenü/Servicecommands:21/0, Öffnen/Schließen/Fokus, fehlgeschlagener
  Auftrag als reine Anzeigeprojektion geprüft. Frühere native Sichtprüfung19/0.
- Flugdeckregression34/0; Kontextcursor12/0.
- Unveränderte HUD-Projektionen behalten Portrait-Instanzen. Kein FPS-/Lasttest.

Nutzercheckpoint ausschließlich gelesen: Satellitenauftrag failed, keine
Completion-Receipt, keine Chips in Schiff/Rucksäcken. Ursache oder Zeitpunkt des
Fehlschlags sind dadurch nicht nachgewiesen; Schlafen als Ursache nicht reproduziert.
Kein Nutzersave verändert. Isolierte APPDATA-Profile für alle Engineprüfungen.

Frühe rote Prüfläufe (falscher kapitalisierter Nodepfad, wiederholtes Absetzen eines
bereits durch seinen Trupp ausgestiegenen Piloten) waren Verifierfehler. Echte
Regressionsbefunde beim Portrait-Routing und veralteten Boarding-Feedback wurden
vor abschließenden grünen Läufen korrigiert. Keine allgemeine Spielabnahme,
Mainintegration oder neue EXE für diesen Task. Separate ältere Basistestfehler
siehe vorangehende Flugdeck-QA; hier nicht erneut zum grünen Gesamtstand erklärt.
