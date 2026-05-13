# TASK_378 - MapEditor Patrol Route Preview

## Ziel
Der MapEditor soll beim Hover oder Auswaehlen eines Patrol-Spawns die komplette Patrol-Route sichtbar hervorheben.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll und gut begrenzt. Der Editor hat bereits `MapEditorPatrolTool` und ausgelagerte Scenario-Panel-Pfade; die Preview sollte diese Daten lesen und nicht neue Patrol-Datenhaltung einfuehren.

## Problem
Patrol-Routen sind im Editor schwer schnell zu pruefen, besonders wenn mehrere Routen und Enemy-Bindings existieren.

## Ursache
Der Patrol-Tooling-Pfad kann Punkte setzen/bearbeiten, aber Hover-/Binding-Kontext wird visuell noch nicht stark genug verbunden.

## Umfang
- Hover/Selection auf Patrol-ID, Spawn-ID oder Binding-ID erkennt zugehoerige Route.
- Route als Linie mit Waypoint-Nummern und optionaler Richtung anzeigen.
- Preview aus `TerrainMapData.get_patrol_path()` und Scenario-Bindings lesen.
- Keine Editor-Daten beim Hover mutieren.
- 2D- und falls vorhanden Primary-View-Refresh sauber dirty/batched halten.

## Akzeptanzkriterien
- [x] Hover auf Patrol-ID hebt komplette Route hervor.
- [x] Direction/Waypoint-Reihenfolge ist lesbar.
- [x] Mehrere Routen koennen nacheinander ohne stale Preview angezeigt werden.
- [x] Dirty-UI-Batching aus TASK_359 wird respektiert.
- [x] Headless-Test prueft Preview-Snapshot fuer mindestens zwei Routen.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/editor/map_editor_patrol_tool.gd`
- ggf. `scripts/editor/map_editor_patrol_preview.gd`
- `scripts/tests/task_378_mapeditor_patrol_route_preview.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_378_mapeditor_patrol_route_preview.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_360_mapeditor_mission_scenario_panel_extraction.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Vorschau darf nicht mit dem Patrol-Editiermodus kollidieren. Hover-Preview und aktives Dragging muessen klar getrennt sein.
