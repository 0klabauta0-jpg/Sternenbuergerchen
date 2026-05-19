# TASK_486 - Map Builder Tooling Spike

## Status: IMPLEMENTIERT

## Ziel / Problem
- Der eigene Map Editor ist fuer schoene Karten weiterhin zaeh: Asset-Auswahl, Rotation, Strassen-/Wasseranschluesse und Gebaeudeplatzierung fuehlen sich eher wie Datenpflege als wie Levelbau an.
- Externe bzw. Godot-native Werkzeuge wie GridMap, MeshLibrary und Asset-Placer-Plugins koennen den Baufluss verbessern, duerfen aber keine zweite Gameplay-Wahrheit neben `TerrainMapData` erzeugen.

## Sinnhaftigkeit / Ursache
- Unsere Runtime braucht Tile-Wahrheit: `type_id`, `object_type_id`, Surface, Hoehe, LOS, Walkability, Rotation und Scale.
- Godot-Werkzeuge sind gut fuer Platzierung und Sichtarbeit, kennen aber unsere Mission-/Terrain-Contracts nicht automatisch.
- Ein kleiner Adapter-Spike kann zeigen, ob Godot-native Authoring-Daten in unsere Map-Wahrheit kompiliert werden koennen, ohne den bestehenden Editor umzubauen.

## Umfang
- Einen dokumentierten Godot-native Builder-Import/Compile-Vertrag fuer GridMap-/Asset-Placer-artige Szenen definieren.
- Einen kleinen GDScript-Adapter bauen, der authoring-nahe Node-/Dictionary-Daten in `TerrainMapData` uebersetzt.
- Rotation, Scale, Surface-/Road-/Water-Platten und Objekt-Layer beim Import absichern.
- Einen Headless-Verifier fuer den Adapter und die empfohlenen Plugin-/GridMap-Entscheidungen ergaenzen.

## Nicht-Ziele
- Kein Vendor-Drop eines externen Plugins in den Produktivbaum.
- Kein Rewrite des Map Editors.
- Kein vollstaendiges MeshLibrary-Automationssystem.
- Keine Dock-/Harbor-Sonderwalkability und keine Door-/Computer-Runtime-Interaktion.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- Godot GridMap: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
- Godot Asset Placer: https://godotengine.org/asset-library/asset/4244

## Akzeptanzkriterien
- Der Spike beschreibt eine klare Empfehlung: GridMap/MeshLibrary fuer modulare Boden-/Wandteile, Asset-Placer-artiger Workflow fuer Props, unser Adapter als Gameplay-Compiler.
- Der Adapter erzeugt `TerrainMapData`, ohne UI-/Editor-State zur Wahrheit zu machen.
- Terrain-/Surface-Platten schreiben die Basis-`type_id`; Objekt-Assets bleiben auf `object_type_id`.
- Road-/Water-Surfaces bleiben erhalten, wenn danach Gebaeude/Props importiert werden.
- Rotation und Scale aus Authoring-Daten werden normalisiert in `TerrainTileData` uebernommen.
- Headless-Test prueft Exportvertrag, Layering, Surface-Persistenz und Dokumentation.

## Betroffene Dateien
- `docs/tasks/TASK_486_map_builder_tooling_spike.md`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `scripts/editor/map_builder_scene_importer.gd`
- `scripts/tests/task_486_map_builder_tooling_spike.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_486_map_builder_tooling_spike.gd`
- relevante TASK_485/TASK_484/TASK_483-Regressionen
- `git diff --check`

## Risiken / offene Punkte
- Der Spike ersetzt keinen manuellen Godot-Editor-Sichttest mit echtem Plugin.
- Ein spaeterer Plugin-Einbau muss gesondert gegen Godot 4.6.2, Lizenz, Editor-Stabilitaet und Repo-Groesse entschieden werden.
- MeshLibrary-Erzeugung aus allen vorhandenen Assets bleibt Folgearbeit, wenn der Adapterpfad ueberzeugt.
