# TASK_380 - Terrain Adjacency Solver Indicator

## Ziel
Der MapEditor soll Debug-Hinweise fuer den Terrain-Adjacency-Solver anzeigen, damit Cliff-/Wall-/Object-Nachbarschaftsupdates nachvollziehbar werden.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist nach TASK_357 sinnvoll als Diagnose-Overlay, nicht als neuer Solver. TASK_357 hat bereits Dirty-Neighborhood-Diagnosewerte; dieser Task soll sie sichtbar und pruefbar machen.

## Problem
Wenn Cliff-/Wall-Adjacency falsch aussieht, ist im Editor schwer zu erkennen, welche Nachbarn neu berechnet wurden und wo der Solver gerade arbeitet.

## Ursache
Dirty-Neighborhood- und Refresh-Diagnose existieren als Daten, sind aber nicht direkt in der Editor-Oberflaeche sichtbar.

## Umfang
- Bestehenden Dirty-Neighborhood-Snapshot aus TASK_357 anzeigen.
- Recomputed Tiles, Seed Tiles und Nachbarn optisch unterscheiden.
- Optional kurzer Inspector-Text mit Counts: seeds, candidates, deduped, refreshed.
- Anzeige als Debug-Toggle, default aus.
- Keine erneute Vollkarten-Rescan-Logik einfuehren.

## Akzeptanzkriterien
- [x] Overlay zeigt Seeds und betroffene Nachbarschaft nach Paint/Height-Aenderung.
- [x] Counts stammen aus bestehendem Debug-Snapshot.
- [x] Toggle aus: keine zusaetzlichen Debug-Visuals.
- [x] Headless-Test prueft Snapshot nach Einzel-Tile- und Brush-Stroke-Aenderung.
- [x] TASK_357-Verifier bleibt gruen.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- ggf. `scripts/editor/map_editor_adjacency_debug_overlay.gd`
- `scripts/tests/task_380_terrain_adjacency_solver_indicator.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_380_terrain_adjacency_solver_indicator.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_357_mapeditor_height_cliff_dirty_neighborhood_cache.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Debug-Layer darf Performance-Fixes aus TASK_357 nicht wieder aufweichen.
