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

## Palette Search, Favorites and Presets
- Palette-Suche ist ein reiner UI-/Authoring-Filter auf Katalog-Displayname, Type-ID und Gruppe.
- Favoriten und Recent-Assets sind Editor-Hilfen. Sie duerfen keine Tile-, Terrain- oder Gameplay-Wahrheit speichern.
- Der Favoritenfilter zeigt Favoriten und zuletzt genutzte Assets, damit haeufige Station-/Factory-/Pipe-/Wall-Teile ohne Kategoriejagd erreichbar bleiben.
- Scale-Presets nutzen denselben Placement-Scale-Pfad wie die Spinbox. Der gespeicherte Tile-Wert bleibt `object_scale`.
- 1.6 bleibt als wichtiger Korrekturwert sichtbar, weil einige Kit-Teile bewusst ueber den Authoring-Scale angepasst werden muessen.
- Der Usability-Snapshot nennt Suchbegriff, Favoriten, Recent, Trefferzahl, Preview-Groessen und Scale-Presets.

## Persistent Palette Authoring Preferences
- Palette-Favoriten, Recent-Assets und Placement-Scale duerfen als lokale Arbeitspräferenz unter `user://map_editor_builder_preferences.json` persistiert werden.
- Diese Datei ist kein Map-Format, kein Terrain-Format und keine Gameplay-Wahrheit. Sie speichert nur Editor-Komfort fuer den lokalen Autor.
- Der Map-Editor laedt die Praeferenz beim Start und speichert sie bei Favoriten-, Recent- oder Placement-Scale-Aenderungen.
- Der Usability-Snapshot nennt Pfad, Schema, Lade-/Speicherstatus und `ui_sets_gameplay_truth = false`.

## Asset Scale Override Presets
- Pro Palette-`type_id` darf ein lokaler `asset_scale_override` gespeichert werden, damit haeufig korrigierte Kit-Teile beim Auswaehlen automatisch ihren Placement-Scale setzen.
- Scale-Overrides leben in derselben `user://`-Authoring-Praeferenz wie Favoriten und Recent-Assets. Sie werden nicht in Map-JSON geschrieben und sind keine Gameplay-Wahrheit.
- Das Setzen eines Overrides speichert nur den Placement-Default fuer zukuenftige Pinselstriche; bereits gesetzte Tiles behalten ihren eigenen `object_scale`.
- Der Usability-Snapshot nennt Override-Liste, Count, Selected-Override und weiter `ui_sets_gameplay_truth = false`.

## Asset Rotation Override Presets
- Placement-Rotation ist ein lokaler Authoring-Default in 90-Grad-Schritten fuer neue Brush-Platzierungen.
- Pro Palette-`type_id` darf ein lokaler `asset_rotation_override` gespeichert werden, damit haeufig ausgerichtete Door-, Wall-, Factory- oder Station-Teile beim Auswaehlen automatisch ihre Placement-Rotation setzen.
- Rotation-Overrides leben in derselben `user://`-Authoring-Praeferenz wie Favoriten, Recent und Scale-Overrides. Sie werden nicht in Map-JSON geschrieben und sind keine Gameplay-Wahrheit.
- Neue Brush-Platzierungen schreiben den aktuellen Placement-Default nach `object_rotation_degrees`; bereits gesetzte Tiles bleiben unveraendert.
- Der Usability-Snapshot nennt Placement-Rotation, Override-Liste, Count, Selected-Override und weiter `ui_sets_gameplay_truth = false`.
- Auto-Rotation/Snapping fuer Drag-Ketten und geteilte Team-/Projektprofile brauchen separate Vertraege.

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

## Aktuelle Gebaeude
- Habitat und Freihafenhalle verwenden den [Mehrzellen-Vertrag](editor_building_authoring_contract.md).
- Ihre Platzierung, Rotation, Verschiebung und Entfernung veraendern Modell und alle reservierten Tiles atomar; jeweils ein vorhandener Undo-Schritt.
- Kategorie `gebaeude` zeigt diese beiden aktuellen Vorlagen. Modulare Kit-Strukturen bleiben unter `space_station` verfuegbar.
- Der MapData-Prop speichert Rotation/Scale fuer diese Gebaeude; die Tile-Objektwerte markieren nur ihre Hinderniszellen.

## Runtime Builder Workbench
- Der primaere Zielworkflow ist der Sternenbuergerchen-Map-Editor, nicht ein Godot-Editor-Dock.
- `scenes/editor/map_builder_workbench.tscn` dient als F6-Einstieg fuer Sichttests und startet im sichtbaren Spielmodus den Runtime-Map-Editor `scenes/editor/map_editor.tscn`.
- Der Map-Editor darf eine linke Builder-Toolleiste anbieten, solange sie bestehende Authoring-Kommandos ausloest und keine zweite Tile-/Mission-Wahrheit speichert.
- Quick-Tools fuer Terrain, Road und Asset waehlen nur Katalog-`type_id`s aus und aktivieren den vorhandenen Brush.
- Erase, Height, Marker, Patrol und Rotation bleiben Wrapper um bestehende Editor-Funktionen.
- Der Godot-Plugin-/GridMap-Pfad bleibt ein Legacy-/Compiler-Fallback und darf nicht als alleiniger Zielworkflow fuer spielbare Editor-Bedienung gelten.

## Network Drag Tools
- Sichtbare Linienwerkzeuge fuer den aktuellen Station-/Outpost-Builder sind Pipe, Wall und Cliff.
- Road- und Rail-Line bleiben vorbereitete/Legacy-Backend-Pfade fuer Tests oder spaetere Karten, sind aber kein sichtbarer Hauptworkflow fuer den aktuellen Builder.
- Ein Drag-Stroke baut einen orthogonalen Pfad aus Start- und End-Tile und ist ein Undo-Schritt.
- Varianten werden aus lokalen Verbindungen abgeleitet: End, Straight, Corner, Split und Cross, soweit die Asset-Familie diese Teile besitzt.
- Auto-Snapping muss dieselbe Piece-Aufloesung fuer Preview und Apply verwenden: Grid, Connection-Mask, Piece-Key, Type-ID und Rotation werden als read-only Snapshot ausgegeben.
- Der Grundstrassensatz nutzt `spacekit_terrain_road_straight`, `spacekit_terrain_road_corner`, `spacekit_terrain_road_end`, `spacekit_terrain_road_split` und `spacekit_terrain_road_cross`.
- Rails nutzen `spacekit_rail*`, Pipes nutzen `spacekit_pipe*`; beide bleiben Object-Layer-Assets und duerfen vorhandene Ground-/Road-/Water-Surfaces nicht ueberschreiben.
- Factory-, SpaceKit-, StationSet-, Modular-, Wall- und Cliff-Prefixe duerfen den Placement-Scale nutzen, damit zu grosse Kit-Teile lokal korrigierbar bleiben.
- Logistik-Bedeutung wie Energie, Oel, Rohstoffe oder Abwasser wird nur vorbereitet. Die echte Ressourcen-/Pipeline-Simulation gehoert in einen spaeteren Gameplay-Contract.
- Aktive Network-Tools liefern einen kompakten Drag-Preview-Snapshot mit Art, Start, Ziel, Pfadlaenge, Segmenten, lesbarem Label und `ui_sets_gameplay_truth = false`.
- Der Drag-Preview-Snapshot liefert zusaetzlich Handles fuer Start, Zwischenpunkte und Target sowie Segmentnummern mit Orientierung. Diese Daten sind nur Lesbarkeitshilfen und duerfen keine Tile- oder Gameplay-Wahrheit setzen.
- Die FullHD-Art-Direction im `Primary3DView` darf Handle-, Segment- und Auto-Snap-Piece-Daten als `Label3D`-Overlays anzeigen. Diese Labels sind transiente Preview-Visuals, verschwinden bei Apply/Cancel/Toolwechsel und setzen keine Tile-Wahrheit.
- Sichtbare Drag-Preview-Linien fuer Pipe, Wall und Cliff lesen ausschliesslich diesen Snapshot. Apply/Cancel/Toolwechsel muessen die Preview loeschen; echte Tile-Aenderungen passieren erst ueber den bestehenden Network-Apply-Pfad.

## Station Doors
- `M+T` ergänzt das vorhandene Mauer-Ziehwerkzeug: ein Zug setzt die Mauer und
  ein mittiges gerades Zweizellen-Tor. Die Vorschau markiert beide Torzellen.
  Ganze Strecke und angrenzende Anschlüsse werden vor dem Schreiben geprüft;
  unzulässige Belegung oder fehlende Assets erzeugen keine Teilmauer.
- Rahmen/Blatt verwenden vorhandene Stationassets und genau ein bestehendes
  Scenario-Interaktionsbinding mit `door_cells`. MapData besitzt den Marker;
  Runtimezustand bleibt beim Mission-/SimulationRoot-Vertrag. Karte und Szenario
  werden über ihre vorhandenen Speicheraktionen gespeichert.
- Mauer, Marker und Binding teilen einen Undo-Schritt und das vorhandene
  Hex-Redo. Andere Marker/Interaktionen werden dabei nicht zurückgesetzt.
- Space-Station-Tueren werden im Editor als Authoring-States behandelt: Closed, Half und Open.
- Quick-Brushes nutzen `station_wall_door`, `station_set_door_single_closed`, `station_set_door_single_half` und `station_set_door_single`.
- Double-Door-Varianten (`station_set_door_double_closed`, `station_set_door_double_half`, `station_set_door_double`) bleiben im Authoring-Contract sichtbar und ueber die Palette nutzbar.
- Der Editor speichert weiterhin nur Tile-Typ, Rotation und Scale; er erzeugt keine zweite Runtime-Tuer-Wahrheit.
- Spaetere Runtime-Animation darf aus Closed/Half/Open-Assetfamilien ableiten, muss aber einen eigenen Door-/Computer-Interaction-Contract bekommen.

## Mission Interaction Points
- Door-, Computer- und Hold-/Capture-Punkte werden als Marker-Authoring vorbereitet, nicht als Editor-Gameplay.
- `interaction_door`, `interaction_computer` und `interaction_hold_zone` sind platzierbare Editor-Marker fuer spaetere Scenario-Bindings.
- Der zugehoerige Runtime-Contract lebt in `docs/dev/mission_interaction_point_contract.md`.
- Markerposition, Tile-Asset und Scenario-Gate duerfen verbunden werden; Door-State, Computer-Fortschritt und Capture-Erfolg bleiben Runtime-/`SimulationRoot`-Wahrheit.
- Der Editor darf diese Punkte sichtbar labeln und validieren, aber keine Mission als abgeschlossen, geoeffnet oder gehalten markieren.

## Scale
- Neue Objekt-/Struktur-Assets koennen mit einem Platzierungs-Scale gepinselt werden.
- Der gespeicherte Tile-Wert ist `object_scale`.
- `object_scale` wird auf einen sicheren Bereich geklemmt. TASK_483 nutzt 0.25 bis 2.5, damit 1.6 als korrigierender Authoring-Wert moeglich ist.
- Der Default ist 1.0. Defaultwerte duerfen beim Speichern ausgelassen werden.
- Eraser setzt `object_scale` wieder auf 1.0, wenn das Objekt oder die Struktur entfernt wird.
- Visuals multiplizieren ihren bestehenden Mapping-Scale mit `object_scale`; Mapping-Skalen bleiben weiterhin im Asset-Mapping.
- Die Kenney-`Modular Space Kit`-Modelle sind in 4er-Modul-Einheiten authoriert. Ihr Mapping-Scale nutzt `0.25`, damit `modular_wall`/`modular_gate` ein Tile breit bleiben, waehrend groessere Raum-/Korridor-Teile bewusst multi-tile sind.

## Naechste Editor-Slices
- Weitere Politur der sichtbaren Drag-Preview fuer Pipe-, Wand- und Cliff-Linien: Handles, Segmentnummern und finale FullHD-Art-Direction.
- Auto-Rotation/Snapping fuer Ketten von Waenden, Tueren und Cliffs.
- Scenario-Binding und Runtime-Snapshot fuer Door-/Computer-/Hold-Interactions.
- Geteilte Asset-Override-Profile pro Team oder Projekt.
