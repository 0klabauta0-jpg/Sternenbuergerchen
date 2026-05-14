# TASK 411 - Large Map Scale Profile 128 und 256

## Ziel / Problem

Nach den Terrain-/HPA-/Batching-Arbeiten ist offen, welche Kartengroesse als naechster realistischer Zielpunkt taugt. Es braucht eine reproduzierbare 128x128- und 256x256-Profilkarte mit gemischtem Terrain, Hills, Nature-Props, Station-/Modular-Assets, FoW und einigen Runtime-Units, ohne riesige JSON-Fixtures ins Repo zu schreiben.

## Ursache / Sinn

64x64 ist aktuell durch HPA-, FoW- und Render-Smokes abgedeckt. Die naechsten Risiken liegen bei grossen Tile-Scans, HPA-Builds, Render-Batching, verbleibenden Einzelobjekten und Runtime-Navigation ueber grosse Karten. Ein Headless-Profil soll zuerst Struktur und breite lokale Budgets messen, bevor echte Content-Maps oder Streaming-Architektur entstehen.

## Umfang

- Generierte In-Memory-Profilkarten fuer 128x128 und 256x256.
- Terrain-Mix mit Ground/Sand/Rock/Road, Hoeheninseln, Slopes/Cliffs, Nature-Props und Station-/Modular-Setpiece-Zonen.
- Registry-, HPA-, FoW-, Runtime-Unit- und `TerrainMap3DView`-Render-Snapshots fuer 128x128.
- 256x256 wird als logische Grosskarte mit Registry/HPA/FoW/Runtime profiliert; der 256x256-Full-Render ist als separater Heavy-Probe dokumentiert, weil der erste headless Full-Render-Lauf nach 10 Minuten nicht fertig wurde.
- HPA-Portal-Sortierung wird aus dem Portal-Insert-Hotspot ans Build-Ende verschoben, damit 128x128/256x256-Builds nicht quadratisch an der Sortierung haengen.
- Breite Gates fuer Struktur, Coverage und grobe Dauerfelder; keine engen maschinenabhaengigen Framezeit-Versprechen.
- Performance-Bericht fuer die Auswertung und naechste Entscheidung.

## Nicht-Ziele

- Keine gespeicherten 128x128-/256x256-Map-JSONs.
- Kein Streaming, Chunk-Unloading oder inkrementeller HPA-Rebuild.
- Keine Gameplay-Regelaenderung.
- Kein neuer visueller Stil oder Asset-Import.
- Kein hartes Produktionsbudget fuer 256x256 auf allen Maschinen.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`
- `docs/tasks/TASK_408_static_nature_prop_multimesh_batching.md`
- `docs/tasks/TASK_410_hpa_profile_visibility_and_registry_revision.md`
- `docs/performance/2_5d_rendering_profile_report.md`
- `docs/performance/navigation_pathfinding_los_profile_report.md`

## Akzeptanzkriterien

- 128x128-Profil meldet 16384 Tiles und 256 HPA-Cluster.
- 256x256-Profil meldet 65536 Tiles und 1024 HPA-Cluster.
- FoW scannt fuer beide Profilkarten alle Tiles und liefert sichtbare Tiles.
- 128x128-Render-Snapshot zaehlt alle Tiles, Ground-Batching, Nature-Prop-Batching und Station-/Modular-Setpiece-Coverage.
- 256x256 dokumentiert, dass der Full-Render aus dem automatisierten Gate ausgeschlossen ist, solange der Heavy-Probe den Headless-Lauf blockiert.
- Runtime-Unit-Probe triggert HPA-Diagnosen im `SimulationRoot`.
- Der Test gibt eine kurze maschinenabhaengige Profilzusammenfassung aus, ohne die Werte als finale Produktionsbudgets zu behandeln.

## Betroffene Dateien

- `scripts/tests/task_411_large_map_scale_profile.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `docs/performance/large_map_scale_profile_report.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_411_large_map_scale_profile.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_411_large_map_scale_profile.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_410_hpa_profile_visibility_and_registry_revision.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_126_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_409_terrain_registry_lookup_hpa_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- 256x256 ist headless logisch gruen, kann aber im echten Viewport weiter GPU-/Culling-/Editor-UX-Probleme zeigen. Der manuelle Godot-Profiler bleibt danach Pflicht.
- Der Test erzeugt grosse In-Memory-Strukturen. Er ist bewusst ein gezielter Profil-Smoke und sollte nicht in jeden schnellen Regression-Run aufgenommen werden.
- Full-Render ueber 64x64 bleibt bewusst ausserhalb dieses automatisierten Gates, bis der Renderer/Editor fuer grosse Karten gestreamt oder sichtbar gechunkt wird.
