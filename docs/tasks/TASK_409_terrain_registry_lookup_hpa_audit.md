# TASK 409 - TerrainRegistry Lookup und HPA Build Audit

## Ziel / Problem

Das Terrain-Review hat zwei kleine, aber echte Skalierungsrisiken in der Terrain-Laufzeitlogik markiert: `TerrainRegistry.get_tile_by_id()` scannt alle Tiles linear, und `get_nearest_walkable_grid()` sortiert pro Anfrage die komplette Tile-Liste. Zusaetzlich ist der HPA-Build nur als Full-Rebuild sichtbar, ohne messbare Build-Diagnose.

## Ursache / Sinn

Die Render-Seite ist inzwischen fuer viele statische Tile- und Prop-Instanzen gebatcht. Damit werden Terrain-Queries und Navigation-Builds als naechste risikoarme Skalierungsstellen interessanter. Die Gameplay-Wahrheit bleibt in `TerrainTileData`/`TerrainRegistry`; dieser Task soll nur Lookup-Arbeit reduzieren und HPA-Build-Kosten sichtbar machen.

## Umfang

- `TerrainRegistry` bekommt einen Tile-ID-Index mit sicherem Fallback, falls Editor-/Undo-Pfade Tile-Daten in-place aendern.
- `get_nearest_walkable_grid()` behaelt das deterministische Distanz-/Grid-Tie-Breaking, sortiert aber nicht mehr alle Tiles pro Anfrage.
- `get_sorted_tiles()` nutzt einen kleinen sortierten Cache, ohne den Rueckgabe-Array fuer Aufrufer teilbar zu machen.
- `HPANavigationGraph` speichert Build-Diagnosen wie Tile-, Cluster-, Komponenten-, Portalanzahl und Build-Dauer.
- Verifier prueft Lookup-Stabilitaet, in-place Mutationen, deterministic nearest-walkable und HPA-Build-Stats.

## Nicht-Ziele

- Kein Umbau der Pathfinding-Semantik.
- Kein inkrementeller HPA-Cluster-Rebuild in diesem Schritt.
- Kein Editor-Button fuer CoverPlacementLab.
- Keine Aenderung an Cover-, LOS-, Hoehen-, Edge- oder Combat-Regeln.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_126_hpa_navigation_foundation.md`
- `docs/tasks/TASK_127_hpa_pathfinder_integration.md`
- `docs/tasks/TASK_184_gameplay_hill_semantics_patch.md`

## Akzeptanzkriterien

- Tile-ID-Lookups sind indexbasiert und bleiben nach Re-Register und in-place Tile-ID-Aenderungen korrekt.
- Nearest-walkable liefert weiter stabile Ergebnisse nach Distanz und Grid-Koordinaten und beruecksichtigt aktuelle Walkability.
- Sortierte Tile-Iteration bleibt deterministisch und schuetzt den internen Cache vor externen Array-Mutationen.
- HPA-Build-Diagnose meldet fuer 64x64/8er-Cluster 4096 Tiles und 64 Cluster.
- Bestehende HPA-/Hill-Semantik-Verifier bleiben gruen.

## Betroffene Dateien

- `scripts/terrain/terrain_registry.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/tests/task_409_terrain_registry_lookup_hpa_audit.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_409_terrain_registry_lookup_hpa_audit.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_409_terrain_registry_lookup_hpa_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_126_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_224_fog_of_war_tile_visibility_height_cover_runtime.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die nearest-walkable-Suche bleibt bewusst exakt und scannt walkable Kandidaten linear. Sie entfernt die teure Sortierung, ersetzt aber noch keinen echten spatial nearest-neighbor Index.
- HPA-Build-Stats machen Full-Rebuild-Kosten sichtbar. Inkrementelle Cluster-Rebuilds sollten erst nach konkreter Messung/Editor-Repro gebaut werden.
