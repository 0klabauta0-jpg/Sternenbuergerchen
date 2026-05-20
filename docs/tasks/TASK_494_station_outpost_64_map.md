# TASK_494 - Station Outpost 64x64 Map

## Ziel / Problem
Zum Testen des neuen Runtime-Map-Editor-Flows wird eine groessere, direkt ladbare 64x64-Map gebraucht, die nicht nur leere Bodenplatten enthaelt.

## Sinnhaftigkeit / Ursache
Die letzten Editor-Slices haben Builder-Leiste, Station-Assets, Door-States, Pipes, Wall-/Cliff-Werkzeuge und Scale-Korrektur vorbereitet. Eine konkrete Map macht diese Pfade sichtbar pruefbar und gibt eine Basis fuer manuelles Weiterbauen.

## Umfang
- Neue 64x64-Map `res://maps/station_outpost_64x64.json`.
- Reproduzierbarer Generator unter `scripts/tools/`.
- Station-/Outpost-Layout mit Station-Floors, Waenden, Tueren, Computern, Containern und Innenraeumen.
- Hoehenregionen, Huegel, Cliffs, Rock-/Nature-Cover und Factory-/Pipe-Bereich.
- Marker fuer Spawn, Objective, Rally, Danger/Recon und Patrol-Preview.
- Verifier, der Map-Groesse, Asset-Mix, Door-States, Hoehen/Cliffs und Marker prueft.

## Nicht-Ziele
- Kein fertiges Balancing fuer eine Mission.
- Keine neue Runtime-Tueranimation.
- Keine Pipeline-/Ressourcen-Simulation.
- Kein Szenario-JSON mit Gegnergruppen in diesem Slice.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_493_map_editor_station_builder_focus.md`
- `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`

## Akzeptanzkriterien
- Die Map laedt ueber `TerrainMapData.load_from_file` ohne Load-Issue.
- Die Map ist exakt 64x64 und enthaelt 4096 Tiles.
- Die Map enthaelt Station-Elemente, Door-States, Factory-Assets, Pipes, Cliffs und Hoehenfelder.
- Alle verwendeten `type_id`-/`object_type_id`-Werte existieren im Terrain-Katalog.
- Spawn-/Objective-/Rally-/Recon-/Danger-Marker sind gesetzt.

## Betroffene Dateien
- `maps/station_outpost_64x64.json`
- `scripts/tools/generate_station_outpost_64x64.gd`
- `scripts/tests/task_494_station_outpost_64_map.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tools/generate_station_outpost_64x64.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_494_station_outpost_64_map.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Map ist eine Authoring-/Playtest-Basis, kein final gebalanctes Einsatzszenario.
- Door-Closed/Half/Open sind als Assets platziert, nicht als animierte Runtime-State-Maschine.
- Bei sichtbarem F6-Test kann die genaue Asset-Groesse einzelner Factory-/Station-Elemente noch nachjustiert werden.
