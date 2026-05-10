# TASK_321 - Manual Playtest Map Editor Station Floor Layering Undo

## Ziel
Station-Floor-Panels sollen als Boden nutzbar sein, auf derselben sichtbaren Oberkante wie Station-Wand-Unterboeden liegen und sich mit Station-Strukturen/Props auf einem Tile kombinieren lassen.

## Status: IMPLEMENTIERT

## Kontext
Im Map-Editor standen manche Station-Floor-Panels zu hoch. Ausserdem sollten Med-Beds, Computer und andere Station-Props neben bzw. auf Station-Strukturen existieren koennen, ohne Waende zu verdraengen. Undo sollte mehr als einen Schritt koennen.

## Umfang
1. Station Floor als Terrain/Surface:
   - `station_floor_panel` ist Terrain-/Surface-Variante statt Object-Layer-Prop.
   - Station-Wand-Tiles bekommen darunter das passende Station-Floor-Panel.
2. Visual Top Alignment:
   - Dicke Ground-Surface-Modelle nutzen ihren eigenen `surface_top_y_offset`.
   - `station_floor_panel` nutzt den Mapping-Offset und sitzt sichtbar tiefer.
   - Gameplay-`surface_y` bleibt von der visuellen Modelloberkante getrennt.
3. Layering:
   - `station_wall` und `station_wall_door` liegen auf einer Structure-Schicht.
   - Station-Props koennen zusaetzlich in `object_type_id` liegen.
4. Eraser / Undo:
   - Eraser entfernt zuerst den Object-Layer, danach die Struktur.
   - Undo-Stack wurde auf mehrere Schritte erweitert.
5. Palette:
   - Kleine Preview-Icons wurden fuer Palette-Eintraege ergaenzt.

## Nicht-Ziele
- Kein echtes drittes gespeichertes Floor-Feld.
- Keine automatische Multi-Tile-Raumgenerierung.
- Keine finale visuelle Bewertung aller importierten Assets.

## Akzeptanzkriterien
- [x] Station-Floor-Panels verhalten sich wie Bodenpaint.
- [x] Station-Waende behalten ihren passenden Boden.
- [x] Props koennen auf Station-Strukturen liegen.
- [x] Eraser entfernt Layer in nachvollziehbarer Reihenfolge.
- [x] Station-Floor-Oberkante nutzt den Mapping-Offset und steht nicht mehr zu hoch.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/terrain/terrain_tile_catalog.gd`
- `data/terrain_tile_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `data/terrain_surface_visual_theme_catalog.json`
- `scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`
- `docs/tasks/TASK_321_manual_playtest_map_editor_station_floor_layering_undo.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_map_editor_station_floor_structure_undo.gd`
- [x] `task_229_map_editor_usability_authoring_pass.gd`
- [x] `task_295_map_editor_paint_toolbar_tools_polish.gd`
- [x] `task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- [x] `task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `editor_height_edge_surface_anchor_verifier.gd`
- [x] `hill_mechanics_16x16_testmap_verifier.gd`
- [x] `task_292_editor_hill_cliff_grid_depth_repair.gd`
- [x] `git diff --check`

## Risiken
- Das Datenmodell bleibt bei `type_id` plus `object_type_id`; echte Floor-/Structure-/Object-Dreifachpersistenz ist ein spaeterer Task, falls noetig.
