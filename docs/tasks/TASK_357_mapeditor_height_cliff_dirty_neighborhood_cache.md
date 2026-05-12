# TASK_357 - MapEditor Height Cliff Dirty Neighborhood Cache

## Ziel
Hoehen-, Cliff- und Wall-Visuals sollen beim Malen nur fuer eindeutig betroffene Dirty-Nachbarschaften neu berechnet werden, ohne dieselben Nachbarn innerhalb eines Brush-Strokes mehrfach zu pruefen.

## Status: GEPLANT

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
- [ ] Ein Brush-Stroke mit Radius > 1 aktualisiert jede betroffene Cliff-/Wall-Nachbarschaft maximal einmal pro Operation.
- [ ] Hoehenkanten, untere Cliff-Visuals, Corners und Walls sehen nach dem Patch identisch zum vorherigen Verhalten aus.
- [ ] Einzel-Tile-Painting bleibt direkt responsiv.
- [ ] Headless-Verifier deckt flache Tiles, Hoehenkante, Corner und Wall-Nachbarschaft ab.
- [ ] Keine neue Terrain-Wahrheit ausserhalb von `TerrainMapData` und bestehendem Renderer.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- ggf. `scripts/editor/map_editor_dirty_neighborhood.gd`
- `scripts/tests/task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`
- ggf. `scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_292_editor_hill_cliff_grid_depth_repair.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Die Logik ist visuell sensibel. Deduplizierung darf nicht dazu fuehren, dass Auto-Cliffs an angrenzenden Tiles stale bleiben.
- Wenn der Task groesser wird, erst Dirty-Sammlung einfuehren und Reconciliation-Ausfuehrung in einem zweiten Task extrahieren.
