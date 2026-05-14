# TASK_217 Navigation Pathfinding LOS Profile Report

Stand: 2026-05-06

## Ziel
Dieser Bericht bewertet Navigation, HPA/A*, Terrain-A*, LOS, Cover, lokale Avoidance und Query-Staggering. Der Task fuehrt Diagnose und breite Budgets ein; er aendert keine Gameplay-Regeln.

## Benchmark-Matrix
`scripts/tests/navigation_benchmark_harness.gd` enthaelt jetzt zusaetzlich zu den TASK_131-Szenarien:

| Szenario | Map | Zweck |
|---|---|---|
| `open_32x32_queries` | 32x32 offen | kleine Baseline fuer Terrain-A* und HPA |
| `hill_cover_32x32_queries` | 32x32 Huegel/Sand/Deckung | Hoehen-, Surface-, LOS- und Cover-Kosten |
| `open_64x64_queries` | 64x64 offen | groessere Query-Baseline |
| `chokepoint_cover_64x64_queries` | 64x64 Engpass/Deckung | lange Pfade, Blocker, LOS/Cover |
| `los_cover_probe` | 32x32 Engpass/Deckung | isolierte LOS-/Cover-Zaehler |
| `query_flood_staggering` | 16x8 offen | viele Commands gegen pro-Tick-Query-Budget |

## Query-Statistik
Jede Path-Batch-Variante liefert:

- `query_time_usec` mit `count`, `min`, `max`, `avg`, `median`, `p95` und `p99`.
- `path_length_stats` mit denselben Feldern fuer Pfadlaengen.
- `status_counts`, `successful_queries`, `total_query_time_usec` und `avg_query_time_usec`.

Die Budgets sind absichtlich breit. Der TASK_217-Verifier prueft nur, dass Median/P95/P99 strukturell vorhanden sind und die HPA-P99-Werte unter einem sehr toleranten lokalen Startbudget bleiben.

## HPA-Build-Diagnose
Die Profilkarten melden zusaetzlich `hpa_graph_build_stats`:

- `built`
- `cluster_size`
- `tile_count`
- `cluster_count`
- `component_count`
- `portal_count`
- `elapsed_usec`
- `incremental` fuer Full- vs. Dirty-Cluster-Rebuilds
- `dirty_grid_count`, `dirty_cluster_count` und `rebuilt_cluster_count`, wenn ein inkrementeller Rebuild laeuft

Fuer 64x64-Karten mit 8x8-Clustern erwartet der Harness 4096 Tiles und 64 Cluster. Der `SimulationRoot` spiegelt dieselben Runtime-Werte in `get_navigation_debug_snapshot()["hpa_navigation"]` und ergaenzt `build_count`, `cache_hit_count` und `registry_revision`. Damit ist sichtbar, ob eine grosse Karte wirklich HPA neu baut oder nur den Runtime-Graphen aus dem Cache nutzt.

Seit TASK_412 trackt `TerrainRegistry` Dirty-Grids, und `SimulationRoot` kann bei gleicher Registry und gleicher Tile-Anzahl den bestehenden HPA-Graphen ueber `rebuild_dirty_clusters_from_registry()` reparieren. Die Runtime-Diagnose markiert diesen Pfad mit `runtime_rebuild_mode = incremental`.

Der Map-Editor besitzt aktuell keinen eigenen HPA-Full-Rebuild-Pfad. Editor-Painting veraendert Terrain-/Visualdaten; HPA-Build-Kosten werden deshalb im Runtime- und Benchmark-Pfad gemessen, nicht in einem Editor-HPA-Loop.

## LOS und Cover
`TerrainPathfinder` zaehlt ueber optionale `options["diagnostics"]`:

- `exposure_score_calls`
- `los_check_count`
- `cover_check_count`

Die Zaehler sind read-only Diagnosewerte. LOS und Cover nutzen weiterhin dieselbe Grid-/Tile-Semantik wie die bestehenden Huegel- und Cover-Tasks; es gibt keine Approximation, die Gameplay-Regeln ersetzt.

## Cache-Diagnose
Der aktuelle Navigation-Harness dokumentiert Cache-Diagnose explizit:

- `path_cache_supported: false`
- `hit_count: 0`
- `miss_count: query_count`
- `invalidation_count: 0`
- `diagnostic: no_path_cache_layer_in_navigation_harness`

Das ist ein bewusster Befund, kein versteckter Cache. Falls spaeter eine Cache-Schicht kommt, muss sie diese Diagnosefelder weiter bedienen und Invalidation sichtbar machen.

## Avoidance und Staggering
TASK_131-Avoidance-Szenarien bleiben erhalten und werden von TASK_217 weiter mitgeprueft. Zusaetzlich begrenzt `query_flood_staggering` acht Move-Commands auf zwei neue Path-Queries im ersten Tick und erwartet sichtbare Delays/Pending-Queries.

## Headless Gate
`scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd` prueft:

- 32x32- und 64x64-Matrix vorhanden.
- Terrain-A* und HPA loesen die Profilqueries.
- Median/P95/P99 existieren.
- HPA-Build-Stats fuer grosse Karten sind sichtbar.
- LOS-/Cover-Zaehler sind in den Cover-/Engpass-Szenarien aktiv.
- Cache-Diagnose ist sichtbar.
- Query-Flood wird per Tick gestaffelt.
- Dieser Bericht enthaelt die relevanten Prueffelder.

## Risiken
- Headless-Zeiten sind maschinenabhaengig und dienen erst als Startbaseline.
- Ein echter Cache wuerde Invalidation-Risiken einfuehren und braucht einen eigenen engen Task.
- LOS/Cover duerfen weiter nicht in UI- oder Visual-Code zur zweiten Wahrheit werden.
