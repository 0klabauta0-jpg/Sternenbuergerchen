# TASK_412 - Large Map Streaming und inkrementelles HPA

## Ziel / Problem
128x128- und 256x256-Karten sind logisch erreichbar, aber voll aktive 3D-Renderläufe blockieren große Karten. HPA nutzt Registry-Revisionen, baut bei Terrain-Änderungen aber noch komplett neu.

## Sinnhaftigkeit / Ursache
TASK_411 zeigte: HPA/FoW/Runtime-Logik sind für 128x128 und 256x256 grün, der Full-Render-Probe lief aber in den Headless-Timeout. Große Karten brauchen deshalb sicht-/kameranahe Visual-Chunks und HPA-Dirty-Cluster statt pauschaler Vollarbeit.

## Umfang
- Automatisches Visual-Streaming im `TerrainMap3DView` für Karten oberhalb des sicheren Full-Render-Bereichs.
- Chunk-Fenster um den aktuellen Kamerafokus mit Diagnosewerten im Render-Snapshot.
- Registry-Dirty-Grids als Grundlage für inkrementelle HPA-Rebuilds.
- Inkrementelle HPA-Rebuild-API für geänderte Cluster und angrenzende Portal-Cluster.
- Runtime-Integration im `SimulationRoot`, damit vorhandene HPA-Graphen bei kleinen Terrain-Änderungen wiederverwendet werden.
- Verifier für Streaming-Render und HPA-Dirty-Cluster-Verhalten.

## Nicht-Ziele
- Kein finaler Content-Map-Umbau.
- Kein echtes Asset-Streaming von Disk.
- Keine Gameplay-Wahrheit im Renderer.
- Kein Editor-UX-Redesign.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_411_large_map_scale_profile.md`
- `docs/performance/large_map_scale_profile_report.md`

## Akzeptanzkriterien
- Große Karten rendern im 3D-View nur aktive Chunk-Fenster, behalten aber die komplette logische Tile-Anzahl im Snapshot.
- Kamerabewegung über Chunk-Grenzen triggert einen gezielten Visual-Refresh.
- 64x64 bleibt im Full-Render-Pfad kompatibel.
- HPA kann nach Dirty-Grids inkrementell reparieren, ohne den bestehenden Graphen zu ersetzen.
- `SimulationRoot` nutzt Dirty-Grids für HPA-Inkrementalrebuilds, wenn Tile-Anzahl und Registry gleich bleiben.
- Lokale Verifier laufen grün.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/terrain/terrain_registry.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_412_large_map_streaming_incremental_hpa.gd`
- `docs/performance/large_map_scale_profile_report.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Prüfung
- `godot_console.exe --headless --path . --script scripts/tests/task_412_large_map_streaming_incremental_hpa.gd`
- Relevante bestehende Terrain-/HPA-/Batching-Verifier.
- `git diff --check`

## Risiken / offene Punkte
- Visual-Streaming reduziert Render-Arbeit, ersetzt aber keinen manuellen Godot-Profiler-Lauf im echten Fenster.
- Die erste HPA-Inkrementalstufe rebuildet geänderte Cluster und angrenzende Portal-Cluster. Weitere Optimierung ist möglich, falls Editor-Painting auf sehr großen Karten weiterhin sichtbar stockt.
