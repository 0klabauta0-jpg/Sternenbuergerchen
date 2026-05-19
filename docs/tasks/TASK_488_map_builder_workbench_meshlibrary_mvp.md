# TASK_488 - Map Builder Workbench MeshLibrary MVP

## Status: IMPLEMENTIERT

## Ziel / Problem
- Wir wollen nicht weiter im alten Map Editor kleinteilig gegen Asset-Auswahl, Rotation und Vorschau kaempfen.
- Nach TASK_486/TASK_487 fehlt der konkrete Godot-Builder-Arbeitsplatz: GridMap fuer modulare Boden-/Wand-/Strassen-Teile, Asset-Placer-kompatible Props und ein Compile-Schritt in unsere Map-Wahrheit.

## Sinnhaftigkeit / Ursache
- Godot GridMap/MeshLibrary ist fuer rasterbasierte 3D-Bausteine gedacht und passt gut zu Tile-, Surface-, LOS- und Hoehenwahrheit.
- Godot Asset Placer ist installiert, aber seine Nodes duerfen nur Authoring-Input sein.
- Unser Runtime-/Mission-Code braucht weiter `TerrainMapData`; deshalb muss der Builder kompilieren statt Runtime-State aus Editor-Plugins zu lesen.

## Umfang
- Eine kleine Editor-Workbench-Szene unter `scenes/editor/map_builder_workbench.tscn` anlegen.
- Ein Manifest mit 15 GridMap-/MeshLibrary-Kernitems fuer Boden, Strassen, Wasser, Modular-Walls, Tueren und Station-Floors/Walls definieren.
- Asset-Placer-kompatible Prop-Nodes mit stabilen `sb_*`-Metadaten fuer Gebaeude, Rover, Satellitenschuessel und Computer vorbereiten.
- Den Importer um einen kombinierten GridMap-plus-Node-Compile-Pfad erweitern.
- GridMap-Yaw-Rotation beim Compile als `object_rotation_degrees` uebernehmen.
- Einen CLI-Compile-Runner und einen Headless-Verifier ergaenzen.

## Nicht-Ziele
- Kein vollstaendiger Ersatz des bestehenden Map Editors.
- Keine automatische MeshLibrary-Erzeugung fuer alle Assets.
- Kein Door-/Computer-Runtime-Interaction-Verhalten.
- Keine zweite Gameplay-Wahrheit in GridMap, MeshLibrary, Asset-Placer-Collections oder Workbench-UI.

## Relevante Contracts / Dokumente
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_486_map_builder_tooling_spike.md`
- `docs/tasks/TASK_487_install_godot_asset_placer.md`

## Akzeptanzkriterien
- Die Workbench-Szene laedt headless und erzeugt eine `MeshLibrary` mit mindestens 15 Kernitems.
- GridMap-Zellen kompilieren ueber `item_id -> type_id` nach `TerrainMapData`.
- Asset-Placer-kompatible Prop-Nodes mit `sb_type_id` und `sb_grid_position` werden im selben Compile-Lauf uebernommen.
- Road-/Water-Surfaces bleiben erhalten, wenn spaeter Props auf denselben Tiles liegen.
- Eine rotierte GridMap-Zelle wird mit nicht-null `object_rotation_degrees` in die Map kompiliert.
- Ein CLI-Skript kann die Workbench nach JSON speichern.

## Betroffene Dateien
- `data/map_builder_workbench_manifest.json`
- `scenes/editor/map_builder_workbench.tscn`
- `scripts/editor/map_builder_workbench.gd`
- `scripts/editor/compile_map_builder_workbench.gd`
- `scripts/editor/map_builder_scene_importer.gd`
- `scripts/tests/task_488_map_builder_workbench_meshlibrary_mvp.gd`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_488_map_builder_workbench_meshlibrary_mvp.gd`
- `godot_console.exe --headless --path . --script scripts/editor/compile_map_builder_workbench.gd -- --output=user://task_488_cli_workbench_output.json`
- `godot_console.exe --headless --path . --script scripts/tests/task_486_map_builder_tooling_spike.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Editor-Test bleibt wichtig: Workbench-Szene oeffnen, GridMap-Palette pruefen, Asset Placer auf `AssetPlacerProps` setzen und eine kleine Map speichern.
- MeshLibrary ist in diesem MVP per Manifest/generated Runtime-Resource an die Workbench gebunden; eine dauerhaft gespeicherte `.tres`-MeshLibrary fuer Team-Editing kann spaeter folgen.
- Road-/Floor-Rotation und Gebaeude-Rotation teilen sich weiterhin den einen `TerrainTileData.object_rotation_degrees`-Wert, wenn beides auf demselben Tile liegt.
