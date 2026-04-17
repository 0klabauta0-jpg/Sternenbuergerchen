# TASK_062 – Map-Editor: Tile-Properties bearbeiten

- Phase: 13 – Map Editor
- Status: offen
- Abhaengigkeiten: TASK_061 (Editor-Szene)

## Ziel
Im Editor koennen die Terrain-Eigenschaften eines ausgewaehlten Tiles veraendert werden.

## Anforderungen
1. Property-Panel zeigt editierbare Felder fuer das ausgewaehlte Tile:
   - `walkable` (Checkbox)
   - `blocks_los` (Checkbox)
   - `cover_value` (SpinBox 0-100)
   - `height_level` (SpinBox 0-3)
   - `surface_type` (Dropdown: ground, road, sand, rock)
2. Aenderungen wirken sofort auf die Farbmodulation des Tile-Sprites
3. Aenderungen werden in den lokalen TerrainMapData-Zustand uebernommen
4. Batch-Modus: optionaler Pinsel-Modus zum schnellen Setzen einer Eigenschaft auf mehrere Tiles (z.B. "alle angeklickten Tiles auf road setzen")
5. Undo fuer die letzte Aenderung (einfacher Ein-Schritt-Undo)

## Akzeptanzkriterien
- Jede Eigenschaft laesst sich aendern und ist sofort visuell sichtbar
- Aenderungen bleiben im Speicher bis zum naechsten Laden/Speichern
- Pinsel-Modus funktioniert fuer mindestens `surface_type` und `walkable`

## Nicht in diesem Task
- Speichern nach JSON (kommt in TASK_063)
- Tile-Sprites wechseln / neue Tile-Typen
- Kartengroesse aendern
