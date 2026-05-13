# TASK_360 - MapEditor Mission Scenario Panel Extraction

## Ziel
Die Mission-Scenario-Authoring-UI soll aus `MapEditor.gd` in ein eigenes Panel oder einen eigenen Controller gezogen werden, ohne Verhalten oder Datenvertrag zu aendern.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll und passt zur bestehenden Dokumentation `docs/dev/map_editor_module_split.md`: Dort blieb das Scenario-Panel bewusst noch im Editor-Skript. Inzwischen ist es ein guter naechster Schnitt, weil Mission-Szenario-Controls, Validierung, Live-Test und UI-Sync einen grossen zusammenhaengenden Block bilden.

## Problem
`scripts/editor/map_editor.gd` bleibt mit ueber 6000 Zeilen ein monolithischer Koordinator. Scenario-Authoring ist fachlich vom Terrain-Painting trennbar, liegt aber noch inline im Mainframe.

## Ursache
TASK_163 hat zuerst kleine Tool-Helfer extrahiert und das Scenario-Panel wegen direkter Kopplung an `MissionScenarioData` und Editor-to-Live-Verifier im MapEditor gelassen.

## Umfang
- Neues Panel/Controller-Skript fuer Mission-Scenario-Authoring einfuehren, z. B. `scripts/editor/map_editor_mission_scenario_panel.gd`.
- Aufbau, Signalverbindungen, Refresh, Sync, Validierung und Live-Test-Anfragen aus `MapEditor.gd` herausloesen.
- `MapEditor.gd` bleibt Koordinator fuer `TerrainMapData`, Save/Load, Dirty-State und 2.5D-View.
- Keine Aenderung am gespeicherten JSON-Format oder `MissionScenarioData`-Vertrag.
- Bestehende Editor-to-Live-Tests weiter nutzen.

## Akzeptanzkriterien
- [x] `MapEditor.gd` verliert den Scenario-Authoring-Block und delegiert an ein klar benanntes Panel/Controller-Objekt.
- [x] Scenario-Controls laden, editieren, validieren und speichern dieselben Daten wie vorher.
- [x] Live-Test-Start funktioniert weiter ueber den bestehenden MapEditor-Koordinator.
- [ ] Bestehende Task-280-/Task-158-/Task-298-Verifier bleiben gruen. Task 280 und Task 298 sind gruen; Task 158 meldet bestehende Assertion-Fails, beginnend vor dem Editor-Load beim alten generischen `lz`-Key-Check.
- [x] Kein neues Gameplay-State-Management in der UI.

## Umsetzung
- `scripts/editor/map_editor_mission_scenario_panel.gd` ist der neue Mission-Scenario-Panel-Controller fuer Control-Aufbau, Signalverbindungen, Refresh, UI-Sync und Panel-Debug-Snapshot.
- `MapEditor.gd` delegiert Scenario-Control-Setup, Signals, Refresh, Sync und Control-Lookups an den Controller. TerrainMapData, ScenarioData-Besitz, Save/Load, Dirty-State, Validierung und Live-Test-Koordination bleiben im MapEditor.
- Der gespeicherte `MissionScenarioData`-/JSON-Vertrag bleibt unveraendert; der neue Task-Verifier prueft UI-Editierung, Save-Contract und Live-Test-Szenenpfad.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/editor/map_editor_mission_scenario_panel.gd`
- ggf. `scenes/editor/map_editor.tscn`
- `scripts/tests/task_360_mapeditor_mission_scenario_panel_extraction.gd`
- ggf. `docs/dev/map_editor_module_split.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_360_mapeditor_mission_scenario_panel_extraction.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_280_tactical_profile_editor_scenario_authoring.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd` - ausgefuehrt, Exitcode 0, aber 15 bestehende Assertion-Fails im alten Live-Smoke-Verifier.
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Task soll ein verhaltensneutraler Schnitt bleiben. Falls dabei neue Scenario-Features auffallen, als separate Tasks erfassen.
- Signalnamen und Panel-Node-Pfade muessen stabil bleiben, damit bestehende Tests nicht wegen reiner Umverdrahtung brechen.
- TASK_158 bleibt als separater Verifier-Konflikt offen: Der erste Fail entsteht schon beim Smoke-Scenario-`to_dict()` durch einen generischen `lz`-Key-Check, der mit neueren Air-/LZ-Threat-Authoring-Feldern kollidiert.
