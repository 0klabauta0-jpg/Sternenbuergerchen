# TASK_490 - Map Builder Paint Tools MVP

## Status: IMPLEMENTIERT

## Ziel / Problem
- Das Map-Builder-Dock war noch kein Editor-Werkzeug, sondern nur ein Einstieg in Godots GridMap/Asset-Placer-Pfad.
- Der Nutzer braucht eine Workbench, in der man Kacheln und erste Props wirklich auswaehlt, in den 3D-Viewport malt, dreht, loescht und danach kompiliert.

## Sinnhaftigkeit / Ursache
- Godots GridMap-Bedienung ist fuer den aktuellen Map-Bau zu versteckt.
- Die Workbench soll funktional pruefbar sein, ohne dass der Nutzer erst Godots interne GridMap-Palette verstehen muss.
- Die Gameplay-Wahrheit bleibt trotzdem `TerrainMapData`: Editor-Painting schreibt nur Authoring-Inputs in `GridMap` und `AssetPlacerProps`, danach kompiliert der bestehende Pfad.

## Umfang
- Das Dock um eine echte Palette aus `data/map_builder_workbench_manifest.json` erweitern.
- Paint-/Erase-/Rotate-Werkzeuge mit linker Icon-Leiste anbieten.
- Linksklick im 3D-Viewport setzt das ausgewaehlte GridMap-Tile auf dem Raster.
- Linksklick mit Prop-Auswahl legt einen `AssetPlacerProps`-Node mit `sb_*`-Metadaten an.
- Q/E oder Dock-Buttons drehen die Platzierung in 90-Grad-Schritten.
- Workbench-Methoden fuer Grid-/Prop-Placement ergaenzen, damit Headless-Verifier den funktionalen Pfad pruefen koennen.

## Nicht-Ziele
- Kein fertiger Terrain-Sculptor.
- Keine automatische Road-/Wall-Auto-Tiling-Logik.
- Keine vollstaendige Asset-Placer-Neuimplementierung.
- Keine Runtime-Gameplay-Wahrheit im Editor-Plugin.

## Relevante Contracts / Dokumente
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md`
- `docs/tasks/TASK_489_map_builder_workbench_editor_entry.md`

## Akzeptanzkriterien
- Das Dock hat Palette, Kategorie-Filter, Paint, Erase und Rotation.
- Das Editor-Plugin verarbeitet 3D-Viewport-Input fuer Paint/Erase.
- GridMap-Tiles werden per Workbench-API gesetzt und kompilieren nach `TerrainMapData`.
- Prop-Nodes werden per Workbench-API angelegt und kompilieren als Objekt-Layer.
- TASK_488 bleibt gruen.

## Betroffene Dateien
- `addons/map_builder_workbench/map_builder_workbench_plugin.gd`
- `scripts/editor/map_builder_workbench.gd`
- `scripts/tests/task_490_map_builder_paint_tools_mvp.gd`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_490_map_builder_paint_tools_mvp.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_489_map_builder_workbench_editor_entry.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_488_map_builder_workbench_meshlibrary_mvp.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Editor-Viewport-Test bleibt offen: Godot starten, Dock `Map Builder` oeffnen, Tile aus Palette waehlen und per Linksklick setzen.
- Auto-Road-/Wall-Snapping, Drag-Paint-Politur und bessere Prop-Thumbnails bleiben Folgearbeit.
