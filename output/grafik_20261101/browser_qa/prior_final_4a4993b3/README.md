# Browserpruefung des lokalen Grafikreports

Ergebnis: **58/58 Pruefungen bestanden**, dazu **3/3 gezielte mobile
Notiz-Pruefungen**. Keine gefundenen Funktionsfehler.

Geprueft mit lokal vorhandenem Chromium/Playwright, `file://`, explizitem
Offline-Kontext und temporaeren getrennten Browserkontexten:

- Desktop 1440 x 1000 und Mobil 390 x 844.
- Eingebettete Vollbilder und tatsaechliche DOM-Bilder geladen.
- Keine Seiten-/Konsolenfehler und keine HTTP(S)-Requests der Reportseite.
- Kein horizontaler Ueberlauf bei Start, nach Bedienung oder im mobilen Dialog.
- Suchfeld, kombinierter Nulltrefferzustand, sechs Gruppenfilter und Vorfassungen.
- Sechs native Engine-Ansichten mit korrekten Bild-/Titelwechseln.
- Schiffsansichten vorn/hinten, Nah-/Abstandsprobe und erklaerte
  Heck-Sperre in der Abstandsprobe.
- Bilddialog, Zoom, Pfeiltasten, Escape und Schliessen; Pfeiltasten in
  Notizfeldern loesen keinen Bildwechsel aus.
- Notizen, Checkboxen, Bild-/Schiffsentscheidungen und aktive Auswahl bleiben
  nach Reload erhalten. Mobile Dialognotiz und Entscheidung sind anklickbar,
  editierbar und nach Wiedereroeffnung vorhanden.
- Zwei tatsaechliche JSON-Downloads mit verschiedenen Zeitstempeldateinamen
  geoeffnet und geparst: Pflichtschema, echte gesetzte Felder/Notizen/Entscheidungen,
  aktive Ansicht/Gruppe/Abstand und Quellenstatus stimmen. Textfallback geprueft.
- Import ist nicht vorhanden und laut bestehendem Workbench-Vertrag optional.

`browser_qa.json` dokumentiert den geprueften HTML-Hash zu Beginn/Ende,
Einzelpruefungen, Browserfehler-/Requestlisten und Screenshotpfade. Die Datei
wurde waehrend dieses Laufs nicht geaendert. `mobile_notes_followup.json`
enthaelt die gezielte mobile Nachpruefung. Die wirklichen Downloads liegen
unter `downloads/`.

Alle sieben abgelegten Screenshots wurden geoeffnet. Die erste Desktopaufnahme
wurde nach expliziter Bilddekodierung wiederholt, damit kein bloss frueher
asynchroner Ladezustand als angeblich fehlendes Bild dokumentiert wird.

Dies ist eine Funktions-/Layoutpruefung des HTML-Reports. Sie ist keine
gestalterische Freigabe der Modelle, keine Gameplay- oder Release-Abnahme.
Die bestehende vollstaendige Browserpruefung und die mobile Notiz-Nachpruefung
wurden nach dem letzten Einbetten aller sechs finalen Godot-Vulkan-Aufnahmen
erneut ausgefuehrt: 58/58 und 3/3 bestanden. `browser_qa.json` enthaelt den
aktuellen finalen HTML-Hash; die Datei blieb waehrend des Laufs unveraendert.
Die finalen Desktop-/Crew-/Mobil-Dialog-Screenshots wurden erneut geoeffnet.
