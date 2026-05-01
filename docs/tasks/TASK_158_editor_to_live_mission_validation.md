# TASK_158 - Editor-to-Live Mission Validation

## Ziel
Der neue Mission-Authoring-Pfad wird gegen die Live-Mission validiert. Ein im Editor gespeichertes Szenario muss mit der 2.5D-Primary-View, Enemy-Waves, Patrols, Objective, Contact-System und taktischen Area Orders sauber spielbar sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_157 - Tactical Mission Editor MVP`
- `TASK_148 - 3D Primary Mission View` oder aktueller 3D-Bridge-Stand im Integrationsbranch
- `TASK_121 - Area Order Marker`
- `TASK_123 - Attack Area Semantik`
- `TASK_112 - ContactTracker und ContactMapOverlay`

## Kontext
Nach dem Editor-MVP braucht es einen verbindlichen Smoke-Test, der nicht nur Daten roundtript, sondern den authorbaren Inhalt im echten Missionspfad prueft.

LZ bleibt Spieleraktion. Der Test darf eine LZ ueber denselben Missions-/Controller-Pfad setzen, aber nicht aus dem Szenario laden.

## Umfang
1. Editor-to-Live-Verifier:
   - Szenario-Datei laden
   - Live-Mission instanziieren
   - Map, Objective, Gegner, Wave-Config und Patrols anwenden
   - pruefen, dass keine LZ aus dem Szenario gesetzt wurde
2. Taktischer Smoke:
   - Spieler-LZ ueber vorhandenen Missionspfad setzen
   - Dropship-Insertion starten
   - Fireteam deployt
   - Attack Area erstellen
   - Contact/Enemy-Wave wird sichtbar
   - Objective kann Fortschritt melden
3. 2.5D-Bridge-Validierung:
   - Unit-/Enemy-Visuals sichtbar
   - Area-Order-Visuals sichtbar
   - Contact-/Patrol-relevante Daten nicht nur im 2D-Fallback haengen
4. Manuelle Checkliste:
   - Editor oeffnen
   - Szenario laden
   - Testmission starten
   - LZ setzen
   - Attack Area ziehen
   - GO ausfuehren
   - Ergebnis/Blocker notieren

## Nicht-Ziele
- Kein neuer Editor-Featureumfang.
- Kein Balancing.
- Kein automatischer Sieg fuer alle Szenarien.
- Keine gespeicherte LZ.

## Architekturregeln
- Verifier prueft Live-Pfade, ersetzt aber nicht SimulationRoot.
- Editor- und Szenario-Daten bleiben Authoringdaten.
- Keine Gameplay-Wahrheit in UI-Widgets oder 3D-Visuals.

## Akzeptanzkriterien
- [x] Ein Editor-Szenario startet in der Live-Mission.
- [x] LZ ist beim Start nicht gesetzt und wird erst ueber den Spielerpfad gesetzt.
- [x] Enemy-Waves und Patrols kommen aus dem Szenario an.
- [x] Attack Area kann in der gestarteten Mission erstellt und ausgefuehrt werden.
- [x] Der aktuelle Live-Visual-Bridge-Stand zeigt Units, Area-Order und Contact-relevante Overlays.
- [x] Manuelle Checkliste ist dokumentiert.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_123_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_112_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/tests/task_158_verifier.gd`
- `docs/manual_checks/editor_to_live_mission_checklist.md`
- ggf. `data/mission_scenarios/editor_validation_smoke.json`

## Risiken
- Wenn der Test zu breit wird, wird er langsam und fragil. Deshalb soll er ein Smoke bleiben und Detailregressionen den vorhandenen Task-Verifiern ueberlassen.
- Der Verifier prueft inzwischen den TASK_159-2.5D-Primary-Pfad: LZ, Dropship, Unit-Proxies, Attack Area, Contact Overlay und Objective-Daten duerfen nicht nur im alten 2D-Fallback sichtbar sein.

## Ergebnis
- `data/mission_scenarios/editor_validation_smoke.json` beschreibt ein kleines Editor-Smoke-Szenario ohne LZ mit Objective, zwei Enemy-Waves und Patrol-Bindings.
- `scripts/tests/task_158_verifier.gd` laedt das Szenario ueber den Editor, speichert es als Live-Test-Scratch, startet die Live-Mission, setzt die LZ ueber den Controller-Pfad, ruft den Dropship, prueft Deploy, Attack Area, Contact Overlay, Objective-Fortschritt und sichtbare Unit-/Enemy-/Area-Visuals in der 2.5D-Primary-View.
- `docs/manual_checks/editor_to_live_mission_checklist.md` dokumentiert den manuellen Editor-to-Live-Durchlauf.
