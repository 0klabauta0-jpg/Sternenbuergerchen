# Map Builder Tooling Spike Contract

## Zweck
Dieser Contract beschreibt den TASK_486-Spike fuer Godot-native Map-Erstellung. Ziel ist ein besserer Baufluss mit Godot-Werkzeugen, ohne dass Editor- oder Plugin-State zur Gameplay-Wahrheit wird.

## Empfehlung
- Modulare Boden-, Strassen-, Wasser-, Wand- und Door-Teile sollen in einem Godot-nativen GridMap-/MeshLibrary-Workflow testbar sein.
- Freie Props, Fahrzeuge, Gebaeude und Deko sollen perspektivisch mit einem Asset-Placer-artigen Editor-Workflow gesetzt werden.
- Unser Projekt behaelt die autoritative Map-Wahrheit in `TerrainMapData`; externe Authoring-Daten werden nur kompiliert/importiert.

## Recherche-Quellen
- Godot GridMap ist fuer 3D-Level aus MeshLibraries auf Rasterbasis gedacht und kann Collision/Navigation an Meshes tragen: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
- Godot Asset Placer 1.4.0 ist ein MIT-lizenziertes Godot-4.3+-Plugin fuer Collections, Snapping, Randomisierung und Surface-/Plane-/Terrain3D-Placement: https://godotengine.org/asset-library/asset/4244
- Terrain3D und Heightmap-Plugins bleiben Kandidaten fuer echte Landschafts-Sculpting-Workflows, sind aber nicht die direkte Tile-Gameplay-Wahrheit dieses Projekts.

## Authoring-Vertrag
- Authoring-Placements enthalten mindestens `type_id` und `grid_position`.
- `grid_position` ist die taktische Tile-Position `Vector2i(x, y)`.
- Bei `GridMap`-Import gilt fuer diesen Spike: Godot-Cell `x/z` wird zu `grid_position.x/y`; optional kann Cell-`y` als `height_level` uebernommen werden.
- Rotation und Scale duerfen aus Metadaten, Node-Transform oder GridMap-Item-Mapping kommen.
- Wenn mehrere Assets auf demselben Tile eigene Rotation/Scale tragen, gewinnt der spaeter kompilierte Layer. Der Importer meldet diese Situation als Warnung, weil `TerrainTileData` aktuell nur eine Rotation und einen Scale pro Tile speichert.

## Layering
- Terrain-/Surface-Platten schreiben `type_id` und `surface_type`.
- Objekt-Layer-Assets schreiben `object_type_id`.
- Struktur-Layer-Assets schreiben `type_id`, erhalten aber vorhandene Surface-Wahrheit.
- Road-/Water-Surfaces duerfen durch spaeter gesetzte Objekte nicht auf `ground` zurueckgesetzt werden.

## Nicht-Wahrheit
- GridMap-Zellen, Asset-Placer-Nodes, Plugin-Collections und Editor-Docks sind Authoring-Inputs, keine Runtime-Wahrheit.
- Runtime, Mission und Pfadkosten lesen weiterhin `TerrainMapData`, `TerrainTileData`, `TerrainRegistry` und bestehende Contracts.

## Folgeentscheidungen
- Erst nach einem echten Godot-Editor-Sichttest entscheiden, ob ein externes Plugin vendored wird.
- Ein spaeterer Task kann MeshLibraries automatisch aus dem Asset-Mapping erzeugen.
- Separater Task noetig, wenn Road-/Floor-Rotation und Gebaeude-Rotation auf demselben Tile getrennt gespeichert werden sollen.
