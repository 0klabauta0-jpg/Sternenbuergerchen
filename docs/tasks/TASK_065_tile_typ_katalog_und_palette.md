# TASK_065 – Tile-Typ-Katalog und Palette

- Phase: 14 – Map-Editor-Workflow und Politur
- Status: implementiert
- Abhaengigkeiten: TASK_064 (MissionTestSetup: Terrain aus JSON laden)

## Ziel
Der Map-Editor soll Tile-Typen aus einem kleinen Katalog lesen und als einfache Palette anbieten, damit Properties nicht mehr nur einzeln pro Tile gepflegt werden muessen.

## Anforderungen
1. Fuehre einen kleinen `TerrainTileCatalog` ein, der Tile-Typ-Definitionen aus `res://data/terrain_tile_catalog.json` laedt.
2. Jeder Tile-Typ definiert mindestens `type_id`, `display_name`, `surface_type`, `walkable`, `blocks_los`, `cover_value` und `height_level`.
3. Der Map-Editor zeigt links eine einfache Palette/Liste mit allen verfuegbaren Tile-Typen.
4. Bei Auswahl eines Tile-Typs wird automatisch der Brush-Modus aktiviert.
5. Klick auf ein Tile uebertraegt die Eigenschaften des gewaehlten Typs auf das Tile.
6. Das Property-Panel zeigt bei selektiertem Tile den erkannten Typ-Namen oder `(custom)` an.

## Akzeptanzkriterien
- Der Katalog laedt Tile-Typen aus der JSON-Datei.
- Die Palette zeigt diese Typen im Editor an.
- Ein ausgewaehlter Typ kann per Brush auf Tiles angewendet werden.
- Das Property-Panel zeigt bei passenden Werten den Tile-Typ, sonst `(custom)`.

## Nicht in diesem Task
- Typ-Referenzen statt Inline-Daten in der Map-JSON
- benutzerdefinierte Tile-Typen zur Laufzeit
- grafische Preview-Kacheln in der Palette
