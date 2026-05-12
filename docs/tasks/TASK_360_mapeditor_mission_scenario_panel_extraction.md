# TASK_360 - MapEditor Mission Scenario Panel Extraction

## Ziel
Die Mission-Scenario-Authoring-UI soll aus `MapEditor.gd` in ein eigenes Panel oder einen eigenen Controller gezogen werden, ohne Verhalten oder Datenvertrag zu aendern.

## Status: GEPLANT

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
- [ ] `MapEditor.gd` verliert den Scenario-Authoring-Block und delegiert an ein klar benanntes Panel/Controller-Objekt.
- [ ] Scenario-Controls laden, editieren, validieren und speichern dieselben Daten wie vorher.
- [ ] Live-Test-Start funktioniert weiter ueber den bestehenden MapEditor-Koordinator.
- [ ] Bestehende Task-280-/Task-158-/Task-298-Verifier bleiben gruen.
- [ ] Kein neues Gameplay-State-Management in der UI.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/editor/map_editor_mission_scenario_panel.gd`
- ggf. `scenes/editor/map_editor.tscn`
- `scripts/tests/task_360_mapeditor_mission_scenario_panel_extraction.gd`
- ggf. `docs/dev/map_editor_module_split.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_360_mapeditor_mission_scenario_panel_extraction.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_280_tactical_profile_editor_scenario_authoring.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Der Task soll ein verhaltensneutraler Schnitt bleiben. Falls dabei neue Scenario-Features auffallen, als separate Tasks erfassen.
- Signalnamen und Panel-Node-Pfade muessen stabil bleiben, damit bestehende Tests nicht wegen reiner Umverdrahtung brechen.
