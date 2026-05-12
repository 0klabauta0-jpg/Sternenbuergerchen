# TASK_333 - Navigation Fallback Budget Contract Alignment

## Ziel
Der Navigation-Fallback soll zum Budget-Contract passen und schlechte Zielpunkte ohne stille Pathfinding-Spikes behandeln. Der Task aendert keine Terrain-Semantik und keine Bewegungsreichweiten.

## Budget-Contract und Export-Default
- `data/performance_budget_contract.json` budgetiert Navigation mit `max_path_query_budget_per_tick = 1`.
- `SimulationRoot` nutzt denselben Export-Default: `navigation_max_new_path_queries_per_tick = 1`.
- Szenen-Overrides fuer `navigation_max_new_path_queries_per_tick`, `navigation_fallback_max_path_attempts_per_request` oder `navigation_fallback_candidate_warning_threshold` sind im aktuellen `res://scenes`-Stand nicht gesetzt.
- Neue Contract-Felder:
  - `max_fallback_path_attempts_per_request = 1`
  - `max_fallback_candidate_warning_threshold = 32`
  - `require_fallback_diagnostics = true`

## Hotspot vorher
Wenn eine Primaerpfad-Anfrage kein Ziel erreichte, konnte `_find_nearest_reachable_walkable_grid` alle walkable Tiles sammeln, sortieren und fuer Kandidaten nacheinander volle Pfade versuchen. Diese internen Pfadversuche wurden nicht als eigene Budget-Grenze sichtbar und konnten besonders bei schlechten Zielpunkten oder getrennten Komponenten CPU-Spitzen erzeugen.

## Aenderung
- `_find_nearest_reachable_walkable_grid` delegiert jetzt an eine budgetierte Fallback-Resolution.
- Die Fallback-Resolution nutzt zuerst den HPA-Graphen:
  - Start-Komponente bestimmen.
  - Alle ueber `get_abstract_neighbors()` erreichbaren Komponenten per BFS sammeln.
  - Nur Tiles aus dieser erreichbaren Komponentenmenge betrachten.
  - Naechsten Kandidaten zum gewuenschten Ziel waehlen.
  - Reachability als komponentengeprueft markieren.
- Ohne HPA-Graph bleibt ein deterministischer nearest-walkable-Fallback, aber ohne versteckte per-candidate-A*-Schleife.
- Pro Move-Request ist maximal ein Fallback-Pfadversuch vorgesehen. Der Debug-Snapshot meldet diese Grenze explizit.

## Fallback-Diagnose
`SimulationRoot.get_navigation_debug_snapshot()` enthaelt jetzt:
- `fallback_resolutions_this_tick`
- `fallback_candidate_count_this_tick`
- `fallback_path_attempts_this_tick`
- `fallback_aborted_this_tick`
- `fallback_candidate_budget_exceeded_this_tick`
- `fallback_candidate_warning_threshold`
- `fallback_max_path_attempts_per_request`
- `last_fallback_diagnostic`

Fallback-Records in `last_queries` tragen zusaetzlich Kandidatenanzahl, Fallback-Pfadversuche, Resolution-Reason und Kandidatenbudget-Warnung.

## Lokale Mess-/Prueflogik
`scripts/tests/task_333_navigation_fallback_budget_contract_alignment.gd` prueft:
- Task-/Status-/Roadmap-/Report-Status.
- Budget-Contract gegen `SimulationRoot` Export-Defaults.
- Keine stillen Szenen-Overrides fuer Navigation-Budgetfelder.
- Kein versteckter per-candidate-A*-Loop im Fallback-Code.
- Disconnected Bad Target: Primaeranfrage plus genau ein Fallback-Pfadversuch; HPA-Komponente liefert zwei Kandidaten und waehlt die naechste erreichbare Kachel.
- Grosse Komponente: 144 Kandidaten erzeugen eine Fallback-Diagnose-Warnung, aber weiterhin nur einen Fallback-Pfadversuch und keinen Mehrfachpfad-Spike.

Lokale Headless-Probe:
- Disconnected Target: `fallback_candidate_count = 2`, `fallback_path_attempts_this_tick = 1`, `path_queries_this_tick = 2`.
- Grosse erreichbare Komponente: `fallback_candidate_count = 144`, `fallback_path_attempts_this_tick = 1`, Warnung `fallback_candidate_count_exceeded_budget`.

## Risiken
- Die Kandidatenwahl scannt bei grossen zusammenhaengenden Komponenten weiterhin die HPA-Komponententiles, aber ohne volle Pfadversuche pro Kandidat. Wiederholt grosse Warnungen sollten in einem spaeteren Terrain-/Command-Targeting-Task adressiert werden.
- Zu harte Abbrueche bei schlechten Zielen koennten Units scheinbar untatig machen. Deshalb war dieser Pass konservativ: Warnen und Pfadversuche budgetieren, aber erreichbare lokale Fallback-Ziele weiter erlauben.
