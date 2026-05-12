# TASK_357 - MapEditor Height Cliff Dirty Neighborhood Cache

## Ziel
Hoehen-, Cliff- und Wall-Visuals sollen beim Malen nur fuer eindeutig betroffene Dirty-Nachbarschaften neu berechnet werden, ohne dieselben Nachbarn innerhalb eines Brush-Strokes mehrfach zu pruefen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist in der Tendenz richtig, aber nicht als pauschales O(N2)-Full-Map-Rescan. Der aktuelle Code aktualisiert meist Tile plus direkte Nachbarn. Bei Hoehen-/Cliff-Reconciliation entstehen aber pro Brush-Stroke viele doppelte Kandidatenpruefungen, besonders bei groesseren Pinseln und automatischen unteren Cliff-Visuals.

## Problem
Ein Brush-Stroke auf mehreren Tiles kann dieselben Cliff-/Wall-/Lower-Neighbor-Kandidaten mehrfach invalidieren und neu bauen. Das erzeugt unnoetige Arbeit und macht spaetere 64x64- oder 80x80-Editor-Sessions empfindlicher.

## Ursache
Dirty-Grid-Sets werden nicht konsequent als einmalige Operation pro Malgeste behandelt. Einzelne Hilfsfunktionen wie `_update_cliff_overlays_around()`, `_update_wall_overlays_around()` und Hoehen-Reconciliation rechnen ihre lokale Nachbarschaft direkt und wiederholt ab.

## Umfang
- Pro Brush-/Height-/Eraser-Operation ein Dirty-Set fuer betroffene Grid-Positionen sammeln.
- Direkte Nachbarn, diagonale Lower-Cliff-Kandidaten und Wall-/Object-Overlay-Kandidaten deduplizieren.
- Reconciliation erst nach dem Sammeln in stabiler Reihenfolge ausfuehren.
- Bestehende visuelle Regeln fuer Cliff, Corner, Slope, Wall und Surface unveraendert lassen.
- Optional kleine Diagnosezaehler fuer betroffene und tatsaechlich aktualisierte Grids in Editor-Snapshots aufnehmen.

## Akzeptanzkriterien
- [x] Ein Brush-Stroke mit Radius > 1 aktualisiert jede betroffene Cliff-/Wall-Nachbarschaft maximal einmal pro Operation.
- [x] Hoehenkanten, untere Cliff-Visuals, Corners und Walls sehen nach dem Patch identisch zum vorherigen Verhalten aus.
- [x] Einzel-Tile-Painting bleibt direkt responsiv.
- [x] Headless-Verifier deckt flache Tiles, Hoehenkante, Corner und Wall-Nachbarschaft ab.
- [x] Keine neue Terrain-Wahrheit ausserhalb von `TerrainMapData` und bestehendem Renderer.

## Umsetzung
- `MapEditor` sammelt Dirty-Grid-Sets pro Brush-/Height-/Property-Operation und aktualisiert Tile-Sprites getrennt von deduplizierten Cliff-/Wall-/Object-Nachbarschaften.
- Cliff-/Wall-Nachbarschaften nutzen ein stabiles Tile+4-Nachbarn-Set, sortiert nach Grid-Position; Object-Overlays bleiben auf die tatsaechlich geaenderten Seeds begrenzt.
- Height-Reconciliation sammelt geaenderte Height-Edges und Lower-Cliff-Visuals, refresht die betroffenen Tile-Sprites und fuehrt erst danach eine gemeinsame Dirty-Nachbarschaft aus.
- Ein Debug-Snapshot `get_dirty_neighborhood_debug_snapshot()` legt Seed-, Rohkandidaten-, deduplizierte Kandidaten- und Refresh-Zaehler fuer Verifier offen.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- ggf. `scripts/editor/map_editor_dirty_neighborhood.gd`
- `scripts/tests/task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`
- ggf. `scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Logik ist visuell sensibel. Deduplizierung darf nicht dazu fuehren, dass Auto-Cliffs an angrenzenden Tiles stale bleiben.
- Wenn der Task groesser wird, erst Dirty-Sammlung einfuehren und Reconciliation-Ausfuehrung in einem zweiten Task extrahieren.
