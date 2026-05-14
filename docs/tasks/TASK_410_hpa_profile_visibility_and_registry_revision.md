# TASK 410 - HPA Profile Visibility und Registry Revision

## Ziel / Problem

TASK_409 macht HPA-Build-Stats im Graphen selbst sichtbar. Fuer echte Entscheidungen reicht das noch nicht: Runtime-Navigation und grosse Kartenprofile muessen diese Werte ausgeben, und der `SimulationRoot` darf einen HPA-Graphen nicht nur anhand gleicher Tile-Anzahl wiederverwenden, wenn die `TerrainRegistry` inhaltlich neu aufgebaut wurde.

## Ursache / Sinn

Das Terrain-Review hat HPA-Full-Rebuilds und Editor-Invalidierung als moeglichen Engpass benannt. Der aktuelle Map-Editor baut selbst keinen HPA-Graphen; der relevante Cache sitzt im `SimulationRoot`-Move-Pfad und in den Navigation-Benchmarks. Deshalb braucht es dort sichtbare Build-/Cache-Diagnosen und eine robuste Registry-Revision als guenstigen Invalidierungsanker.

## Umfang

- `TerrainRegistry` erhaelt eine monotone Revision fuer `clear_tiles()`, `register_tile()` und explizite Tile-Daten-Aenderungen.
- `SimulationRoot` cached HPA-Graphen nach Registry, Tile-Anzahl und Registry-Revision.
- `get_navigation_debug_snapshot()` zeigt HPA-Build-Stats, Build-Count, Cache-Hits und Registry-Revision.
- `navigation_benchmark_harness.gd` gibt HPA-Graph-Build-Stats fuer Profilkarten aus und markiert sie in der Summary.
- Performance-Report ergaenzt die neuen HPA-Build-Diagnosen.
- Verifier prueft Runtime-Cache-Verhalten, Same-Size-Invalidierung, grosse 64x64-Build-Stats und dass der Map-Editor weiterhin keinen HPA-Full-Rebuild-Pfad besitzt.

## Nicht-Ziele

- Kein inkrementeller HPA-Cluster-Rebuild.
- Kein Gameplay-Regelwechsel fuer Movement, Cover, LOS, Hoehen oder Edge Types.
- Kein Editor-UI-Panel fuer HPA-Stats.
- Kein Path-Cache fuer Query-Ergebnisse.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_409_terrain_registry_lookup_hpa_audit.md`
- `docs/tasks/TASK_217_navigation_pathfinding_los_performance_pass.md`
- `docs/performance/navigation_pathfinding_los_profile_report.md`

## Akzeptanzkriterien

- Registry-Revision steigt bei Rebuild-/Register-Operationen und kann explizit fuer in-place Tile-Aenderungen markiert werden.
- `SimulationRoot` baut den HPA-Graphen bei unveraenderter Registry-Revision nicht erneut, diagnostiziert aber Cache-Hits.
- Same-Size-Registry-Rebuilds invalidieren den Runtime-HPA-Cache ueber die Revision.
- 64x64-Benchmark-Szenarien melden HPA-Build-Stats inklusive 4096 Tiles und 64 Clustern.
- Der Map-Editor bleibt HPA-build-frei; HPA-Profiler-Werte stammen aus Runtime/Benchmark, nicht aus Editor-Painting.

## Betroffene Dateien

- `scripts/terrain/terrain_registry.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/navigation_benchmark_harness.gd`
- `scripts/tests/task_410_hpa_profile_visibility_and_registry_revision.gd`
- `docs/performance/navigation_pathfinding_los_profile_report.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_410_hpa_profile_visibility_and_registry_revision.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_410_hpa_profile_visibility_and_registry_revision.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_409_terrain_registry_lookup_hpa_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_126_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Revision ist ein Invalidierungsanker, aber keine inkrementelle HPA-Struktur. Ein spaeterer Editor-Task kann Dirty-Cluster nur sinnvoll bauen, wenn vorher ein echter Editor-Profilinglauf zeigt, dass Runtime-/Benchmark-Full-Builds nicht reichen.
- In-place Aenderungen ausserhalb `register_tile()` muessen `notify_tile_data_changed()` aufrufen, wenn sie einen bereits gebauten Runtime-HPA-Graphen invalidieren sollen.
