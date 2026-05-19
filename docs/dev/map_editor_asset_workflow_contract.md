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
- Wenn ein Palette-Typ einen `texture_path` besitzt, muss die Palette diese echte Preview-Textur anzeigen; generierte Platzhalter sind nur Fallback fuer fehlende Texturen.
- Der aktuell gewaehlte Palette-Typ darf in einem groesseren Preview-Block mit Name, Gruppe und Platzierungs-Scale angezeigt werden.
- Kategorieauswahl darf scrollbar sein; der Asset-Browser darunter bekommt den Hauptplatz.
- Asset-Listen duerfen als mehrspaltiger Icon-Browser dargestellt werden, solange die Palette-Metadaten und Selection-Snapshots stabil bleiben.

## Save As
- Der Map-`Save As`-Dialog ist ein JSON-`FILE_MODE_SAVE_FILE`-Dialog im Projektressourcenbereich.
- Er startet bei `res://maps`, ist nicht per `root_subfolder` auf einen Sonderpfad eingeschraenkt und behaelt den JSON-Filter.
- Pfade ohne `.json` werden beim Speichern normalisiert; projekt-absolute Pfade werden intern wieder als `res://...` referenziert.

## Street and water plates
- Strassen- und Asphaltplatten, die als Boden gebaut werden, sind Terrain-/Surface-Varianten und keine Object-Layer-Props.
- Space-Kit-Strassenplatten schreiben `surface_type = road`, behalten vorhandene Objekt-Layer und werden in der 3D-Ansicht mit derselben Oberkante wie normale Bodenplatten gerendert.
- Wasser-/Flussplatten schreiben `surface_type = water`; spaeter gesetzte Hafen-, Kai-, Gebaeude- oder Objekt-Assets duerfen diese Surface-Wahrheit nicht auf `ground` zuruecksetzen.
- Wasser ist ein Surface-Typ fuer Editor- und Pfadkosten-Wahrheit. Spezielle Schiff-, Schwimm- oder Kai-Walkability-Regeln gehoeren in einen separaten Dock-/Harbor-Task.

## Rotation
- Manuelle Rotation bleibt in 90-Grad-Schritten.
- Rotierbare Assets speichern Rotation pro Tile in `object_rotation_degrees`.
- Rotation ist visuell und authoring-relevant, aber keine zweite Gameplay-Wahrheit.

## Runtime Builder Workbench
- Der primaere Zielworkflow ist der Sternenbuergerchen-Map-Editor, nicht ein Godot-Editor-Dock.
- `scenes/editor/map_builder_workbench.tscn` dient als F6-Einstieg fuer Sichttests und startet im sichtbaren Spielmodus den Runtime-Map-Editor `scenes/editor/map_editor.tscn`.
- Der Map-Editor darf eine linke Builder-Toolleiste anbieten, solange sie bestehende Authoring-Kommandos ausloest und keine zweite Tile-/Mission-Wahrheit speichert.
- Quick-Tools fuer Terrain, Road und Asset waehlen nur Katalog-`type_id`s aus und aktivieren den vorhandenen Brush.
- Erase, Height, Marker, Patrol und Rotation bleiben Wrapper um bestehende Editor-Funktionen.
- Der Godot-Plugin-/GridMap-Pfad bleibt ein Legacy-/Compiler-Fallback und darf nicht als alleiniger Zielworkflow fuer spielbare Editor-Bedienung gelten.

## Network Drag Tools
- Linienwerkzeuge fuer Road, Rail, Pipe, Wall und Cliff sind Runtime-Editor-Werkzeuge.
- Ein Drag-Stroke baut einen orthogonalen Pfad aus Start- und End-Tile und ist ein Undo-Schritt.
- Varianten werden aus lokalen Verbindungen abgeleitet: End, Straight, Corner, Split und Cross, soweit die Asset-Familie diese Teile besitzt.
- Der Grundstrassensatz nutzt `spacekit_terrain_road_straight`, `spacekit_terrain_road_corner`, `spacekit_terrain_road_end`, `spacekit_terrain_road_split` und `spacekit_terrain_road_cross`.
- Rails nutzen `spacekit_rail*`, Pipes nutzen `spacekit_pipe*`; beide bleiben Object-Layer-Assets und duerfen vorhandene Ground-/Road-/Water-Surfaces nicht ueberschreiben.
- Factory-, SpaceKit-, StationSet-, Modular-, Wall- und Cliff-Prefixe duerfen den Placement-Scale nutzen, damit zu grosse Kit-Teile lokal korrigierbar bleiben.
- Logistik-Bedeutung wie Energie, Oel, Rohstoffe oder Abwasser wird nur vorbereitet. Die echte Ressourcen-/Pipeline-Simulation gehoert in einen spaeteren Gameplay-Contract.

## Scale
- Neue Objekt-/Struktur-Assets koennen mit einem Platzierungs-Scale gepinselt werden.
- Der gespeicherte Tile-Wert ist `object_scale`.
- `object_scale` wird auf einen sicheren Bereich geklemmt. TASK_483 nutzt 0.25 bis 2.5, damit 1.6 als korrigierender Authoring-Wert moeglich ist.
- Der Default ist 1.0. Defaultwerte duerfen beim Speichern ausgelassen werden.
- Eraser setzt `object_scale` wieder auf 1.0, wenn das Objekt oder die Struktur entfernt wird.
- Visuals multiplizieren ihren bestehenden Mapping-Scale mit `object_scale`; Mapping-Skalen bleiben weiterhin im Asset-Mapping.
- Die Kenney-`Modular Space Kit`-Modelle sind in 4er-Modul-Einheiten authoriert. Ihr Mapping-Scale nutzt `0.25`, damit `modular_wall`/`modular_gate` ein Tile breit bleiben, waehrend groessere Raum-/Korridor-Teile bewusst multi-tile sind.

## Naechste Editor-Slices
- Freies Wand-/Cliff-Ziehen mit Segment-/Edge-Preview.
- Auto-Rotation/Snapping fuer Ketten von Waenden, Tueren und Cliffs.
- Door-/Computer-Interaction-Contract fuer Runtime-Naehe und Bedienzeit.
- Palette-Suche, Favoriten und gespeicherte Asset-Override-Presets.
