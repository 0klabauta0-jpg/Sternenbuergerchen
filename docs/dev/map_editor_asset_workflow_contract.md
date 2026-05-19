# Map Editor Asset Workflow Contract

## Zweck
Dieser Contract beschreibt den ersten stabilen Asset-Authoring-Workflow fuer den Map Editor. Ziel ist ein schnellerer, menschlicherer Baufluss, ohne dass die UI Gameplay-Wahrheit besitzt.

## Autoritaet
- `TerrainTileData` besitzt pro Tile `type_id`, `object_type_id`, `object_rotation_degrees` und `object_scale`.
- `TerrainTileCatalog` bleibt Quelle fuer Palette-Typen, Displaynamen, Gruppen, Preview-Texturen und Gameplay-Felder.
- `TerrainMapData` speichert und laedt die Tile-Wahrheit.
- `TerrainMap3DView` und `TerrainMapRenderer` lesen diese Werte nur fuer Darstellung.
- Map-Editor-Controls senden Authoring-Commands und zeigen Status; sie sind nicht die Wahrheit.

## Palette
- Palette-Gruppen bleiben aus dem Katalog abgeleitet.
- Innerhalb einer aktiven Gruppe werden sichtbare Assets nach Displayname sortiert.
- Preview-Icons muessen gross genug sein, damit Space-Station-, Modular-, Factory- und Nature-Assets ohne Raten unterscheidbar sind.
- Der aktuell gewaehlte Palette-Typ darf in einem groesseren Preview-Block mit Name, Gruppe und Platzierungs-Scale angezeigt werden.
- Kategorieauswahl darf scrollbar sein; der Asset-Browser darunter bekommt den Hauptplatz.
- Asset-Listen duerfen als mehrspaltiger Icon-Browser dargestellt werden, solange die Palette-Metadaten und Selection-Snapshots stabil bleiben.

## Rotation
- Manuelle Rotation bleibt in 90-Grad-Schritten.
- Rotierbare Assets speichern Rotation pro Tile in `object_rotation_degrees`.
- Rotation ist visuell und authoring-relevant, aber keine zweite Gameplay-Wahrheit.

## Scale
- Neue Objekt-/Struktur-Assets koennen mit einem Platzierungs-Scale gepinselt werden.
- Der gespeicherte Tile-Wert ist `object_scale`.
- `object_scale` wird auf einen sicheren Bereich geklemmt. TASK_483 nutzt 0.25 bis 2.5, damit 1.6 als korrigierender Authoring-Wert moeglich ist.
- Der Default ist 1.0. Defaultwerte duerfen beim Speichern ausgelassen werden.
- Eraser setzt `object_scale` wieder auf 1.0, wenn das Objekt oder die Struktur entfernt wird.
- Visuals multiplizieren ihren bestehenden Mapping-Scale mit `object_scale`; Mapping-Skalen bleiben weiterhin im Asset-Mapping.

## Naechste Editor-Slices
- Freies Wand-/Cliff-Ziehen mit Segment-/Edge-Preview.
- Auto-Rotation/Snapping fuer Ketten von Waenden, Tueren und Cliffs.
- Door-/Computer-Interaction-Contract fuer Runtime-Naehe und Bedienzeit.
- Palette-Suche, Favoriten und gespeicherte Asset-Override-Presets.
