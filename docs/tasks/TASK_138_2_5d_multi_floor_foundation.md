# TASK_138 - 2.5D Multi-Floor Foundation

## Ziel
Eine kleine Grundlage fuer mehrere begehbare Ebenen auf demselben Grid-Bereich schaffen, ohne bereits vollstaendige Innenraeume oder Full-3D-Gameplay einzufuehren.

## Status: IMPLEMENTIERT

## Kontext
- Einfache Hoehen pro Tile reichen fuer Daechern, Plattformen und Graben oft aus.
- Mehrere Etagen brauchen aber einen separaten `floor_index`, damit zwei Positionen mit gleicher Grid-Koordinate logisch unterscheidbar bleiben.

## Umfang
1. Datenmodell fuer `MapFloorSlot` oder aequivalente Floor-Eintraege pro Grid vorbereiten.
2. Unit-/Command-Positionsvertrag um optionalen `floor_index` erweitern.
3. Registry-Lookups fuer `grid + floor_index` bereitstellen.
4. Uebergaenge zwischen Floors nur ueber explizite Links erlauben.
5. Minimaler Testaufbau mit Boden + Dach/Plattform auf gleicher X/Y-Zone.

## Nicht-Ziele
- Keine kompletten Gebaeudeinnenraeume.
- Keine Pathfinding-Optimierung fuer grosse Multi-Floor-Maps.
- Keine UI fuer Etagenfilter.
- Keine echte vertikale Formationslogik.

## Akzeptanzkriterien
- [x] Eine Position kann `grid_position` und `floor_index` tragen.
- [x] Zwei Floor-Slots am gleichen Grid werden logisch getrennt behandelt.
- [x] Movement wechselt Floors nur ueber erlaubte Links.
- [x] LOS kann Floor-Hoehen aus TASK_136 lesen.
- [x] Verifier prueft Boden/Dach-Trennung und erlaubten Floor-Wechsel.

## Umsetzung
- `TerrainTileData` traegt jetzt `floor_index` und explizite `floor_links`; bestehende Tiles bleiben ueber Default `floor_index = 0` kompatibel.
- `MapFloorSlot` bildet einen kleinen Snapshot fuer `grid_position + floor_index + floor_height + floor_links`.
- `TerrainMapData` kann mehrere Slots auf derselben Grid-Koordinate speichern/laden und per `get_tile_at_grid_floor(...)` separat ausgeben.
- `TerrainRegistry` fuehrt floor-indexierte Lookups, Height-Profile und explizite Floor-Transition-Snapshots.
- `TerrainPathfinder` besitzt einen kleinen `find_floor_path(...)`-Foundation-Pfad, der Floor-Wechsel nur ueber `floor_links` erlaubt.
- `LineOfSightSystem` kann per `get_line_of_sight_floor_snapshot(...)` floor-spezifische Hoehen aus der Registry lesen.
- Commander-/FTL-/Unit-Command- und Runtime-Status-Vertraege koennen optional `target_floor_index` transportieren.

## Lokale Checks
- `godot_console.exe --headless --path . --script scripts/tests/task_138_verifier.gd`

## Risiken
- Multi-Floor kann schnell Auswahl, Kamera und Editor verkomplizieren; dieser Task bleibt bewusst nur Daten- und Runtime-Grundlage.
- Bestehende Systeme muessen `floor_index = 0` als Default behalten.
