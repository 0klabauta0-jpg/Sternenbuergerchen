# TASK_322 - Manual Playtest Map Editor Asset Import Rotation Context Menu

## Ziel
Der Map-Editor soll die neu eingebundenen Space-/Factory-/Interior-Assets besser authorbar machen: Preview, Rotation, Layering und Kontextmenue duerfen den Arbeitsfluss nicht blockieren.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Playtest sollten Space Station Kit, Modular Space Kit, Factory Kit, Candy/Interior-Assets und zusaetzliche Kenney-Icons in den Editor. Manche Vorschauen waren nur farbige Quadrate oder zu klein. Einige Assets muessen direkt im Editor drehbar sein. Das Kontextmenue sollte erst beim Loslassen der rechten Maustaste aufgehen, damit eine Area markiert werden kann.

## Umfang
1. Asset-Import:
   - Factory Kit und isometrische Space-Interior-/Space-Kit-Assets liegen projektlokal unter `Assets/curated/kenney/...`.
   - Mapping- und Tile-Kataloge wurden fuer neue Editor-Assets erweitert.
2. Rotation:
   - Rotierbare Assets nutzen `object_rotation_degrees`.
   - Station-/Modular-Floors koennen im UI erreichbar gedreht werden.
3. Preview:
   - Palette-Icons/Previews wurden fuer mehrere Gruppen nachgezogen.
   - Kleine Vorschau bleibt links neben dem Namen und grob schriftgross.
4. Kontextmenue:
   - Rechte-Maus-Kontextmenue oeffnet erst beim Button-Release.
   - Area-Markierung mit rechter Maus wird dadurch nicht sofort unterbrochen.
5. Help:
   - Marker, Settings und Editor-Begriffe bekommen Help-/Popup-Anker.

## Nicht-Ziele
- Keine finale vollstaendige Asset-Balance.
- Kein automatisches Verbinden von Waenden.
- Keine Garantie, dass jedes neue Kit-Asset bereits optimal skaliert ist.

## Akzeptanzkriterien
- [x] Neue Asset-Kits sind projektlokal referenziert.
- [x] Asset-Pfade nutzen `res://...` statt absolute Quellpfade.
- [x] Rotierbare Assets haben UI-Erreichbarkeit.
- [x] Kontextmenue stoert die rechte-Maus-Area-Markierung nicht mehr.
- [x] Palette-Preview ist fuer neue Gruppen sichtbar verbessert.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `data/terrain_3d_asset_mapping.json`
- `data/terrain_tile_catalog.json`
- `data/contextual_help_catalog.json`
- `Assets/curated/kenney/factory/`
- `Assets/curated/kenney/isometric_space_interior/`
- `Assets/curated/kenney/modular_space/`
- `scripts/tests/bugfix_map_editor_asset_rotation_context_menu.gd`
- `scripts/tests/bugfix_editor_hill_marker_asset_import.gd`
- `docs/tasks/TASK_322_manual_playtest_map_editor_asset_import_rotation_context_menu.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_map_editor_asset_rotation_context_menu.gd`
- [x] `bugfix_editor_hill_marker_asset_import.gd`
- [x] `task_251_nature_kit_classic_source_inventory_and_subset_import.gd`
- [x] `run_task_247_asset_locality_scan.ps1`
- [x] `task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- [x] `git diff --check`

## Risiken
- Einige Previews koennen trotz Import noch manuelle Sichtkalibrierung brauchen.
- Neue Assets duerfen nicht still als Gameplay-Blocker wirken, wenn sie nur Dekoration sein sollen.
