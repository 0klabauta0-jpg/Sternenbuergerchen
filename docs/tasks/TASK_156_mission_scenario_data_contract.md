# TASK_156 - Mission Scenario Data Contract

## Ziel
Ein klarer Datenvertrag trennt Karten-/Terrain-Daten von taktischen Missionsszenarien. Dadurch kann der Editor spaeter Szenarien speichern, ohne `TerrainMapData` zur Gameplay-Wahrheit aufzublasen.

## Status: GEPLANT

## Voraussetzung
- `TASK_155 - Tactical Mission Test Presets`
- `TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte`
- `TASK_108 - PatrolEditorTool und Pre-Contact-Patrol`

## Kontext
`TerrainMapData` speichert bereits Terrain, Marker und Patrol-Pfade. Fuer taktische Tests fehlen aber Szenario-Informationen wie Gegnergruppen, Wave-Parameter, Objective-Regeln und Meta-Katalogdaten.

LZ ist nicht Teil dieses Vertrags. Sie wird immer vom Spieler gesetzt.

## Umfang
1. `MissionScenarioData` als kleiner RefCounted-Datenvertrag:
   - `scenario_id`
   - `display_name`
   - `map_file_path`
   - `time_limit_seconds`
   - `mission_slot_count_override` optional
   - `objective` mit Marker-ID oder Position und Capture-Radius
   - `enemy_groups`
   - `wave_config`
   - `patrol_bindings`
   - `notes` optional
2. JSON-Load/Save:
   - robuste Defaults
   - Version-Feld
   - Roundtrip ohne Godot-Scene-Abhaengigkeit
3. Validierung:
   - referenzierte Map existiert
   - Objective ist per Marker oder Position aufloesbar
   - Gegner-IDs sind eindeutig
   - Patrol-Bindings verweisen auf vorhandene Gegner oder Spawn-IDs
   - keine LZ-Felder werden akzeptiert oder serialisiert
4. Live-Mission-Anbindung vorbereiten:
   - `MissionTestSetup` kann spaeter optional ein Szenario erhalten
   - Meta-Katalog kann spaeter aus Szenario-Dateien statt Hardcode lesen

## Nicht-Ziele
- Kein Editor-UI in diesem Task.
- Kein neuer Gegner-KI-Stack.
- Kein Persistieren von Spielerbefehlen.
- Keine LZ im Szenario.

## Architekturregeln
- Szenario-Daten sind Authoring-/Setup-Daten vor Missionsstart.
- Runtime-Mutationen laufen weiter ueber SimulationRoot und bestehende Controller.
- Der Vertrag darf keine NodePath-Pflicht auf konkrete Test-Szenen enthalten.

## Akzeptanzkriterien
- [ ] `MissionScenarioData` laedt und speichert ein Szenario verlustfrei.
- [ ] Validierung meldet fehlende Map, fehlendes Objective und doppelte Gegner-IDs.
- [ ] LZ-Felder werden nicht in den Vertrag aufgenommen.
- [ ] Ein Szenario kann `TerrainMapData` referenzieren, ohne Terrain-Daten zu duplizieren.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_156_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_155_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/mission/mission_scenario_data.gd`
- `data/mission_scenarios/*.json`
- `scripts/tests/task_156_verifier.gd`

## Risiken
- Wenn der Vertrag zu gross wird, entsteht ein zweiter Missionskern. V1 soll nur Start-/Authoringdaten beschreiben.
