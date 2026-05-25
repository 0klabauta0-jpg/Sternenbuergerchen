# TASK_504 - Startmap Expansion Performance Pass

## Ziel / Problem
Die aktuelle Startmission nutzt eine 64x64-Outpost-Map. Fuer echte Playtests ist sie zu klein, und bei groesseren Karten muss frueh sichtbar bleiben, ob der Render-/Load-Pfad sauber ueber Streaming und Registry-Indizes laeuft.

## Sinnhaftigkeit / Ursache
Der gewuenschte Arbeitsmodus ist: die kleine Startmap bleibt als vertrauter Kern erhalten, wird aber als mittleres Feld einer groesseren 3x3-Karte genutzt. Die Umgebung soll aus gestempelten/gedrehten Varianten im gleichen Stil entstehen, ohne Missionsmarker, Spawns oder Objectives achtfach zu duplizieren.

## Umfang
- Neue Startmap `res://maps/station_outpost_192x192.json`.
- Reproduzierbarer Generator, der `station_outpost_64x64.json` als 3x3-Stempelquelle nutzt.
- Die alte 64x64-Startmap wird exakt in den mittleren Sektor der neuen 192x192-Map kopiert.
- Aussen-Sektoren werden gedreht/variiert, behalten Station-, Factory-, Pipe-, Cliff-, Hoehen- und Nature-Charakter.
- Gameplay-Marker und Patrol-Routen werden einmalig in den mittleren Sektor verschoben.
- `frontier_probe` nutzt die neue getrackte Startmap.
- Verifier prueft Map-Integritaet, Center-Preservation und 2.5D-Visual-Streaming fuer die grosse Karte.

## Nicht-Ziele
- Kein neues Missionsbalancing und kein neues Gegner-Szenario.
- Keine neue Terrain-Streaming-Architektur.
- Keine Entfernung der 64x64-Map; sie bleibt Quelle und Regression.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_494_station_outpost_64_map.md`
- `docs/tasks/TASK_500_gameflow_spine_hardening.md`

## Akzeptanzkriterien
- `station_outpost_192x192.json` laedt ohne Load-Issue und enthaelt 36.864 Tiles.
- Der mittlere 64x64-Sektor entspricht der bisherigen Startmap in Tile-/Surface-/Object-/Height-/LOS-Werten.
- Alle neun Sektoren enthalten sichtbaren Terrain-/Asset-Content im Outpost-Stil.
- Marker und Patrol-Routen existieren einmalig und liegen im mittleren Sektor.
- Die 2.5D-Ansicht aktiviert fuer die 192x192-Map Visual-Streaming und rendert nur aktive Chunks statt alle Tiles.
- `frontier_probe` verweist auf die neue getrackte Map.

## Betroffene Dateien
- `maps/station_outpost_192x192.json`
- `scripts/tools/generate_station_outpost_192x192.gd`
- `scripts/tests/task_504_startmap_expansion_performance_pass.gd`
- `scripts/tests/task_500_gameflow_spine_hardening.gd`
- `scripts/meta/meta_layer_flow.gd`
- `docs/tasks/TASK_504_startmap_expansion_performance_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tools/generate_station_outpost_192x192.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_504_startmap_expansion_performance_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_494_station_outpost_64_map.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Karte ist gross genug fuer erste Performance- und Gameplaywege, aber noch kein final gebalanctes Szenario.
- Aussen-Sektoren sind bewusst gestempelte Varianten; manuelles Feintuning im Editor bleibt sinnvoll.
- Der aktuelle grosse JSON-Datensatz ist akzeptabel fuer diesen Slice, aber spaeter kann ein Sparse-/Chunk-Mapformat sinnvoll werden.
