# TASK_379 - MapEditor Tile Property Grid Overlay

## Ziel
Der MapEditor soll einen Debug-Overlay erhalten, der Tile-Eigenschaften wie Walkability, LOS-Block, Cover und Height sichtbar macht.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll fuer Authoring und QA, aber als Debug-/Editor-Overlay, nicht als normale Missionsanzeige. Viele Daten liegen bereits in TerrainMapData/TerrainRegistry.

## Problem
Beim Bearbeiten ist nicht immer klar, welche Tiles wirklich begehbar sind, LOS blocken oder Deckung geben.

## Ursache
Die Tile-Properties werden im Inspector angezeigt, aber nicht direkt auf der Kartenflaeche aggregiert.

## Umfang
- Toggle fuer Tile-Property-Overlay im Editor.
- Farbcodierung fuer Walkable, Blocked, LOS-Block, Cover und Height.
- Legende nur kompakt im Editor-Inspector oder als Tooltip, nicht auf der Karte ueberladen.
- Overlay-Refresh ueber Dirty-Neighborhood/Dirty-UI-Pfade begrenzen.
- Keine Terrain-Daten aus Overlay heraus aendern.

## Akzeptanzkriterien
- [ ] Toggle zeigt Tile-Eigenschaften auf der Karte.
- [ ] Overlay aktualisiert sich nach Paint/Height/Property-Aenderung.
- [ ] Ausgeschaltetes Overlay verursacht keine zusaetzlichen Draw-/Refresh-Kosten.
- [ ] Headless-Test prueft Snapshot-Zaehler fuer aktiv/inaktiv und Property-Farben.
- [ ] Existing Editor-Playability-Smoke bleibt gruen.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- ggf. `scripts/editor/map_editor_tile_property_overlay.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/tests/task_379_mapeditor_tile_property_grid_overlay.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_379_mapeditor_tile_property_grid_overlay.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Zu viele Farben koennen Authoring erschweren. Der Task soll klare Layer-Modi oder reduzierte Palette pruefen.

