# Navigation Fallback Candidate Cap

Dieser Bericht dokumentiert den neuen Kandidaten-Cap fuer Navigation-Fallbacks.

## TASK_341 Ergebnis

- Der Bad-Target-Fallback in `SimulationRoot` sammelt HPA-Kandidaten jetzt ueber eine begrenzte Ring-Suche nahe am Ziel statt ueber komplette `get_component_tiles()`-Listen erreichbarer Komponenten.
- `TerrainRegistry` stellt dafuer `get_grid_bounds()` und `get_tile_count()` bereit, damit der Fallback-Hotpath Bounds und Cache-Invalidierung ohne erneutes Tile-Array-Scannen nutzen kann.
- Der Performance-Budget-Contract enthaelt `max_fallback_candidates_per_request` und verlangt Cap-Diagnosen.

## Diagnosefelder

- `candidate_count` / `candidate_considered_count`: Anzahl tatsaechlich bewerteter Fallback-Kandidaten.
- `candidate_limit`: harte Obergrenze pro Fallback-Aufloesung.
- `candidate_capped` / `candidate_cap_reached`: sichtbarer Cap-Treffer.
- `candidate_search_reason`: `candidate_limit_reached`, `grid_bounds_exhausted`, `no_acceptable_candidates` oder `missing_grid_bounds`.
- `selected_distance_to_desired` / `selected_distance_to_source`: Distanz des ausgewaehlten Fallback-Grids.
- `fallback_candidate_cap_hits_this_tick`: Debug-Snapshot-Zaehler fuer Cap-Treffer im aktuellen Tick.

## Risiko

Das Cap ist bewusst hart. Sehr grosse, duenn besetzte Komponenten koennen dadurch einen nachvollziehbaren nahen Kandidaten waehlen, ohne alle theoretisch erreichbaren Tiles zu betrachten. Falls sich spaeter Karten mit extrem sparse Walkability zeigen, sollte ein separater Terrain-/Navigation-Index-Task folgen statt weiterer Logik im `SimulationRoot`.
