# TASK_263 - Contextual Help Popup UX Contract

## Ziel
Es soll ein gemeinsamer UX-Vertrag fuer kompakte Hilfe-Popups entstehen. Die Hilfe soll erklaeren, was ein Control, Wert, Skill, Befehl oder Loadout-Eintrag bedeutet, ohne lange Einzeiler ueber den Bildschirm zu ziehen oder die Bedienung zu blockieren.

Die Hilfe muss abschaltbar sein und spaeter automatisch auf Abdeckung, Laenge, Layout und Erreichbarkeit geprueft werden koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_256 - Automated Playability Coverage Contract
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- TASK_262 - Playability Regression Gate and Manual Open Items

## Kontext
Das Spiel wird komplexer: Charakterwerte, Raenge, Loadout, Gewicht, Befehlsplatten, FoW, Mission-Control, Editor-Werkzeuge und Multiplayer-Optionen brauchen Erklaerung. Die Hilfe darf aber nicht wie Handbuchseiten im UI wirken. Sie braucht einheitliche Regeln fuer kurze Hinweise, laengere Details, Timing, Abschaltung und Positionierung.

## Umfang
1. Hilfe-Stufen:
   - Kurzhilfe: kompakter Titel plus 1 bis 3 kurze Zeilen.
   - Detailhilfe: bei laengerem Hover oder Help-Modus mit Auswirkungen, Herkunft/Formel, Beispielen.
   - Keine Hilfe: bewusst markierte Controls ohne Erklaerbedarf.
2. Timing:
   - Kurzhilfe nicht sofort, sondern nach kurzer Hover-Zeit.
   - Detailhilfe erst nach laengerem Hover, z. B. 3 bis 4 Sekunden, oder per Pin/Help-Modus.
   - Touch-/Controller-/Keyboard-Fallback ueber Fokus oder Hilfe-Button vorbereiten.
3. Layout-Regeln:
   - Maximalbreite und harte Zeilenumbrueche.
   - Keine Popups ueber halben Bildschirm.
   - Popup bleibt im Viewport und verdeckt nach Moeglichkeit nicht das Ziel-Control.
   - Lange Detailtexte scrollen oder klappen auf, statt Screen zu sprengen.
4. Abschaltbarkeit:
   - Settings-Option fuer Hilfe-Popups.
   - Kleiner globaler Hilfe-Button oben im App-Shell/HUD-Kontext.
   - Optional Modi: aus, kompakt, erweitert.
5. Content-Vertrag:
   - Hilfe-Texte liegen in einem Katalog mit stabilen `help_id`s.
   - Controls referenzieren `help_id`, nicht harte Freitexte ueberall.
   - Pflichtfelder: Titel, Kurztext, Detailtext optional, Screen, Zielgruppe, Status.
6. Qualitaetsregeln:
   - Kein langer Einzeiler.
   - Kein Fachbegriff ohne kurze Erklaerung, wenn er fuer Spieler relevant ist.
   - Keine zweite Gameplay-Wahrheit; Formeln und Effekte muessen aus bestehenden Daten/Vertraegen abgeleitet sein.

## Nicht-Ziele
- Keine finale Hilfe fuer jedes einzelne Control.
- Kein Tutorial-System.
- Keine Dialog- oder Quest-Erklaerungen.
- Keine komplette Accessibility-Architektur.

## Akzeptanzkriterien
- [x] `docs/dev/contextual_help_popup_ux_contract.md` beschreibt Timing, Layout, Stufen, Settings und Content-Regeln.
- [x] `data/contextual_help_catalog.json` ist als Katalogformat definiert.
- [x] Pflichtscreens und Pflichtbereiche fuer Hilfe sind in die Playability-Coverage-Matrix eingetragen.
- [x] Kompakt- und Detailhilfe sind klar getrennt.
- [x] Abschaltbarkeit und globaler Hilfe-Button sind als Vertrag festgelegt.
- [x] Ein Verifier prueft Pflichtabschnitte, Katalogschema und Laengenregeln.

## Erwartete Dateien
- `docs/dev/contextual_help_popup_ux_contract.md`
- `data/contextual_help_catalog.json`
- `docs/qa/playability_coverage_matrix.md`
- `scripts/tests/task_263_contextual_help_popup_ux_contract.gd`
- `docs/tasks/TASK_263_contextual_help_popup_ux_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_263_contextual_help_popup_ux_contract.gd`
- [x] `git diff --check`

## Risiken
- Zu viel Text macht die Hilfe stoerend; zu wenig Text erklaert die Systeme nicht.
- Wenn Formeln in Hilfe-Texten frei erfunden werden, driften sie von Gameplay-Daten ab.

## Ergebnis
`docs/dev/contextual_help_popup_ux_contract.md` definiert den UX-Vertrag fuer kompakte und detaillierte Hilfe-Popups. `data/contextual_help_catalog.json` legt das maschinenlesbare Katalogschema mit Pflichtbereichen, stabilen `help_id`s, Statuswerten, Modi, Timing und Layoutgrenzen an. Die Playability-Coverage-Matrix enthaelt eine eigene Contextual-Help-Coverage-Sektion. Der Verifier prueft Dokumentabschnitte, Katalogschema, Pflichtbereiche, stabile IDs und Textlaengen.

## Naechster Schritt
TASK_264 kann die eigentliche Popup-Komponente, Settings-Anbindung und globale Help-Taste auf Basis dieses Vertrags bauen.
