# TASK_156 - Mission Scenario Data Contract

## Ziel
Ein klarer Datenvertrag trennt Karten-/Terrain-Daten von taktischen Missionsszenarien. Dadurch kann der Editor spaeter Szenarien speichern, ohne `TerrainMapData` zur Gameplay-Wahrheit aufzublasen.

## Status: IMPLEMENTIERT

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
- [x] `MissionScenarioData` laedt und speichert ein Szenario verlustfrei.
- [x] Validierung meldet fehlende Map, fehlendes Objective und doppelte Gegner-IDs.
- [x] LZ-Felder werden nicht in den Vertrag aufgenommen.
- [x] Ein Szenario kann `TerrainMapData` referenzieren, ohne Terrain-Daten zu duplizieren.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_156_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_155_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/mission/mission_scenario_data.gd`
- `data/mission_scenarios/*.json`
- `scripts/tests/task_156_verifier.gd`
- `maps/task_156_contract_map.json`

## Ergebnis
- `MissionScenarioData` ist ein scene-unabhaengiger RefCounted-Vertrag fuer Authoring-/Setupdaten vor Missionsstart.
- JSON-Load/Save nutzt ein `version`-Feld, robuste Defaults und einen kanonischen `to_dict()`-Roundtrip.
- Die Validierung prueft Map-Existenz, Objective-Marker oder Objective-Position, Capture-Radius, eindeutige Gegner-IDs, Wave-Parameter und Patrol-Bindings gegen Gegner- oder Map-Spawn-/Patrol-IDs.
- LZ-nahe Felder werden rekursiv abgelehnt und nie serialisiert.
- Fuenf Szenario-Dateien spiegeln die TASK_155-Presets als editornahe Szenario-Daten, ohne Terrain, Marker, Patrol-Pfade aus `TerrainMapData` oder laufenden Gameplay-State zu duplizieren.
- `maps/task_156_contract_map.json` ist eine kleine Contract-Fixture-Map mit `spawn_alpha`, `spawn_bravo` und `objective_point`, damit der Verifier schnell bleibt.

## Risiken
- Wenn der Vertrag zu gross wird, entsteht ein zweiter Missionskern. V1 soll nur Start-/Authoringdaten beschreiben.
- Der Vertrag bereitet Live-Mission-/Meta-Anbindung vor, schaltet sie aber noch nicht produktiv um. Das bleibt bewusst TASK_157/TASK_158 bzw. Folgearbeit.
