# TASK_157 - Tactical Mission Editor MVP

## Ziel
Der bestehende Map-Editor erhaelt einen schlanken Mission-Authoring-Modus fuer taktische Tests. Designer/Entwickler koennen eine Map laden, Gegnergruppen, Objective-Regeln, Wellen und Patrol-Zuordnungen bearbeiten und ein Szenario speichern.

## Status: GEPLANT

## Voraussetzung
- `TASK_156 - Mission Scenario Data Contract`
- `TASK_061 - Map-Editor-Szene`
- `TASK_063 - Map-Editor: Speichern und Laden`
- `TASK_108 - PatrolEditorTool und Pre-Contact-Patrol`
- `TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte`

## Kontext
Der vorhandene Editor kann Terrain, Marker und Patrols bearbeiten. Fuer taktisches Testen fehlt eine Szenario-Schicht. Diese soll den vorhandenen Editor erweitern, nicht einen zweiten Editor daneben bauen.

LZ wird nicht im Editor gesetzt oder gespeichert.

## Umfang
1. Mission-Authoring-Modus im bestehenden Editor:
   - Szenario laden/speichern
   - aktuelle Map-Datei anzeigen/referenzieren
   - Objective aus Map-Marker oder Position waehlen
   - Capture-Radius und Zeitlimit bearbeiten
2. Gegner-Authoring:
   - Enemy-Slots/Gruppen anlegen
   - Unit-/Archetype-ID setzen
   - Spawn-Marker oder Position setzen
   - Wave-Index oder Delay-Gruppe setzen
   - Patrol-Pfad zuordnen
3. Patrol-/Marker-Wiederverwendung:
   - vorhandene Patrol-Pfade sichtbar zu Gegnern zuordnen
   - Systemmarker bleiben editor-only
4. Test-Start:
   - Button startet die Live-Testmission mit dem Szenario
   - Missionsstart enthaelt keine gespeicherte LZ
   - Spieler setzt LZ im normalen Missionsflow
5. UX bewusst klein:
   - keine komplexe Sidebar-Architektur
   - keine Kampagnen-Save-Verwaltung
   - keine finalen Designer-Tools

## Nicht-Ziele
- Kein Player-facing Map-Editor.
- Keine LZ-Bearbeitung.
- Kein Speichern von Area Orders.
- Keine Animation-/Asset-Kalibrierung.
- Kein Umbau des Meta-Layers in diesem Task.

## Architekturregeln
- Editor schreibt Szenario-Dateien, nicht Live-Gameplay-State.
- Live-Teststart nutzt bestehende MissionSetup-/Meta-Pfade.
- Keine direkten SimulationRoot-Commands aus Editor-Callbacks.

## Akzeptanzkriterien
- [ ] Editor kann ein Szenario laden, bearbeiten und speichern.
- [ ] Gegnergruppen und Wave-Parameter erscheinen nach Live-Start in der Mission.
- [ ] Patrol-Zuordnung aus dem Editor erreicht `EnemyWaveController`.
- [ ] Objective-Regeln werden in `SimulationRoot` gesetzt.
- [ ] LZ wird weder angezeigt noch gespeichert; die Mission wartet weiter auf Spieler-LZ.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_157_verifier.gd`
- [ ] Manuell `scenes/editor/map_editor.tscn` starten, Szenario speichern, Live-Test starten.

## Dateien (voraussichtlich)
- `scripts/editor/map_editor.gd`
- `scenes/editor/map_editor.tscn`
- `scripts/mission/mission_scenario_data.gd`
- `scripts/tests/task_157_verifier.gd`

## Risiken
- Der Editor kann schnell zu gross werden. Der MVP muss nur taktische Testbarkeit liefern, keine finale Leveldesign-Suite.
