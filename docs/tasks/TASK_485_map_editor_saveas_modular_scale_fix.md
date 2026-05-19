# TASK_485 - Map Editor Save As and Modular Scale Fix

## Status: IMPLEMENTIERT

## Ziel / Problem
- Der Map-Editor-Button `Save As` oeffnete den Dialog in einem falschen Datei-Modus und mit Userdaten-Zugriff, wodurch der Pfad wie ein fremder Sonderpfad wirkte und keine normale JSON-Datei-Auswahl moeglich war.
- Die Kenney Modular-Space-Kit-Modelle wurden mit nahezu 1:1 Mapping-Scale gerendert, obwohl die Quellen in 4er-Modul-Einheiten authoriert sind. Dadurch waren `modular_wall`, `modular_wall_corner`, `modular_gate` und verwandte Teile auf der Map deutlich zu gross.
- Space-Kit-Strassenplatten waren als Objekt-Layer mit `surface_type = ground` eingetragen. Beim Setzen wirkten sie wie Props ueber dem Boden und verloren die erwartete Strassen-/Boden-Surface-Wahrheit; Wasser/Kai-Fliesen hatten noch keinen klaren Editor-Surface-Vertrag.

## Sinnhaftigkeit / Ursache
- `SaveAsDialog` war in der Szene als Directory-Open-Dialog mit `ACCESS_USERDATA` serialisiert; der Scriptpfad setzte nur `current_dir` und `current_file`.
- Die bisherigen Modular-Space-Scales lagen bei `0.86`/`0.88`; ein 4.0 breites Wandmodell belegte so mehr als drei 3D-Zellen.
- Strassenplatten kamen aus dem Import-Kit ueber den Objektpfad und setzten `surface_type` auf `ground`, obwohl sie im Editor wie Bodenplatten verwendet werden.

## Umfang
- Map-Save-As als JSON-Save-Dialog im Projektressourcenbereich konfigurieren.
- Ausgewaehlte Projekt-Absolute-Pfade wieder zu `res://` normalisieren.
- Modular-Space-Kit-Scales auf `0.25` setzen, damit ein 4er-Modul einer 3D-Zelle entspricht und groessere Teile bewusst 2x2 bzw. 5x3 bleiben.
- Space-Kit-Strassenplatten als Terrain-/Surface-Varianten mit `surface_type = road` fuehren.
- Wasser als zulaessigen Surface-Typ ergaenzen und `nature_ground_dirt_river_tile` als Wasser-/Flussplatte fuer Hafen-/Kai-Authoring anbieten.

## Nicht-Ziele
- Kein neues Map-Manifest- oder Multiplayer-Speichersystem.
- Keine Door-/Computer-Interaktionslogik.
- Keine Neuorganisation der Palette-Gruppen.
- Keine vollstaendige Hafen-/Kai-Sonderplatzierungslogik; dieser Task stellt nur sicher, dass Strassen- und Wasser-Surfaces beim Layern erhalten bleiben.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- `Save As` nutzt `FileDialog.FILE_MODE_SAVE_FILE`, `FileDialog.ACCESS_RESOURCES`, JSON-Filter und startet bei `res://maps`.
- Der Dialog ist nicht durch einen Root-Subfolder auf einen Sonderpfad eingeschraenkt.
- Save-As-Pfade ohne `.json` bekommen die Endung.
- Projekt-absolute Pfade werden fuer die interne Map-Referenz wieder zu `res://...` lokalisiert.
- Alle Modular-Space-Kit-Modelle im 3D-Mapping nutzen `0.25` und bleiben in ihrem erwarteten Tile-Footprint.
- Strassenplatten aus dem Asset-Katalog schreiben `surface_type = road`, bleiben top-anchored auf derselben Oberkante wie Bodenplatten und bewahren vorhandene Objekt-Layer.
- Wasser-/Flussplatten schreiben `surface_type = water`; spaeter gesetzte Objekte duerfen diese Surface-Wahrheit nicht auf `ground` zuruecksetzen.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scenes/editor/map_editor.tscn`
- `scripts/terrain/terrain_tile_data.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `data/terrain_tile_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `data/terrain_surface_visual_theme_catalog.json`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `scripts/tests/task_485_map_editor_saveas_modular_scale_fix.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_485_map_editor_saveas_modular_scale_fix.gd`
- Relevante Map-Editor-Regressionen aus TASK_483/TASK_484
- `git diff --check`

## Risiken / offene Punkte
- Die Modular-Space-Modelle sind jetzt in der 3D-Map sinnvoll kalibriert; der finale Sichtcheck im Godot-Editor bleibt fuer Lesbarkeit und Kameraeindruck offen.
- Multi-Tile-Snapping fuer grosse Raum-/Korridor-Assets bleibt ein spaeterer Editor-Workflow-Task.
- Wasser ist jetzt als Surface-Typ vorhanden und bewusst teuer/langsam; eine echte Schiff-/Kai-/Schwimm- oder Dock-Walkability-Regel bleibt Folgearbeit.
