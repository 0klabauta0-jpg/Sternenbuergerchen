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
- TASK_487 installiert Godot Asset Placer 1.4.0 unter `addons/asset_placer` und aktiviert es als Editor-Plugin.
- Die Installation enthaelt eine kleine lokale Godot-4.6.2-Kompatibilitaetsbremse: `EditorDock` wird nur in sichtbaren Editor-Sessions genutzt, headless Import/Verifier ueberspringen den Dock-/Panel-UI-Aufbau.
- Asset Placer ist weiterhin nur Authoring-Tooling. Collections, Asset-Placer-Nodes und Plugin-Docks werden nicht zur Gameplay-Wahrheit.
- Die Plugin-Asset-Bibliothek bleibt standardmaessig `user://asset_library.json`; ein gemeinsamer Projektpfad muss spaeter bewusst als Team-Workflow entschieden werden.
- TASK_488 fuehrt eine kleine `MapBuilderWorkbench` ein: `scenes/editor/map_builder_workbench.tscn` erzeugt aus `data/map_builder_workbench_manifest.json` eine GridMap-/MeshLibrary-Palette fuer 15 Kernteile und einen `AssetPlacerProps`-Root fuer freie Props.
- Die Workbench ist der erste regulaere Testpfad: GridMap-Zellen liefern `item_id -> type_id`, Asset-Placer-kompatible Nodes liefern `sb_type_id`, `sb_grid_position`, `sb_rotation_degrees` und `sb_object_scale`.
- Der Compile-Pfad bleibt autoritativ: `scripts/editor/map_builder_scene_importer.gd` uebersetzt GridMap plus Prop-Nodes in `TerrainMapData`; `scripts/editor/compile_map_builder_workbench.gd` kann das Ergebnis als JSON speichern.
- GridMap-Yaw-Rotation wird ueber Godots orthogonalen Index beim Compile in `object_rotation_degrees` normalisiert. Wenn spaeter Boden-/Road-Rotation und Prop-Rotation getrennt gebraucht werden, braucht `TerrainTileData` einen separaten Transform-Speicher.
- TASK_489 macht den Pfad bedienbar: ein eigenes Godot-Dock `Map Builder` sitzt links, nutzt eine Icon-Werkzeugleiste fuer Workbench, GridMap, Props und Compile und zeigt in der F6-Preview ausdruecklich, dass F6 kein Builder-Modus ist.
- TASK_490 macht die Workbench funktional: Das Dock bietet eine Manifest-Palette, Paint/Erase/Rotate und verarbeitet 3D-Viewport-Linksklicks, die GridMap-Zellen oder `AssetPlacerProps`-Nodes schreiben. Diese Authoring-Daten werden weiterhin erst durch den Compile-Pfad zur `TerrainMapData`-Wahrheit.
- TASK_491 korrigiert die Zielschicht: Der eigentliche Builder-Workflow liegt im Sternenbuergerchen-Runtime-Map-Editor. `map_builder_workbench.tscn` ist nun der F6-Einstieg in `map_editor.tscn`; Godot-Dock, GridMap und Asset-Placer bleiben Legacy-/Compiler-Fallbacks und Recherchematerial.
- Ein spaeterer Task kann MeshLibraries automatisch aus dem Asset-Mapping erzeugen.
- Separater Task noetig, wenn Road-/Floor-Rotation und Gebaeude-Rotation auf demselben Tile getrennt gespeichert werden sollen.
