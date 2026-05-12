# TASK_356 - MapEditor Lazy Terrain Texture Catalog

## Ziel
Terrain-Texturen im Editor und gemeinsamen Terrain-Renderer sollen erst bei Bedarf geladen und ueber einen kleinen zentralen Cache wiederverwendet werden.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber die genaue Formulierung ist zu eng. Im aktuellen Stand liegen Terrain-Texturen nicht nur als `preload`-Konstanten in `scripts/editor/map_editor.gd`, sondern werden auch in `scripts/terrain/terrain_map_renderer.gd` vorgehalten und in `scripts/terrain/terrain_tile_catalog.gd` beim Katalogaufbau per `load()` fuer alle Tile-Typen geladen.

## Problem
MapEditor-Start und Editor-Toolwechsel laden mehr Texturen als die aktuelle Session braucht. Das ist einzeln kein VRAM-Drama, addiert sich aber mit 2.5D-Preview, Asset-Palette und Meta-UI zu unnoetiger Startarbeit.

## Ursache
Terrain-Texturzugriff ist historisch verteilt:
- `MapEditor.gd` haelt lokale Texture-Konstanten fuer Preview/Fallbacks.
- `TerrainMapRenderer.gd` haelt eigene Terrain-/Cliff-/Wall-Texturen.
- `TerrainTileCatalog.gd` laedt Katalogtexturen eager beim Erzeugen des Katalogs.

## Umfang
- Einen zentralen, kleinen Terrain-Texture-Cache einfuehren, z. B. unter `scripts/terrain/`.
- `TerrainTileCatalog.get_texture()` auf lazy loading umstellen.
- Gemeinsame Fallbacks fuer fehlende Texture-Pfade beibehalten.
- Doppelte Editor-/Renderer-Preloads reduzieren, ohne sichtbare Terrain-Zuordnung zu veraendern.
- Cache-Schluessel stabil auf `res://`-Pfad oder Tile-Type-ID legen.
- Keine grosse LRU-Komplexitaet einbauen, solange kein Profiling zeigt, dass Godots Resource-Cache nicht reicht.

## Akzeptanzkriterien
- [x] Der Editor kann starten, ohne alle katalogisierten Terrain-Texturen sofort zu laden.
- [x] Erstes Nutzen eines Tile-Typs laedt dessen Textur und nutzt sie danach aus dem Cache.
- [x] Fehlende Texturen erzeugen weiter einen sicheren Fallback statt harter Fehler.
- [x] 2D-Editor, 2.5D-Preview und Live-Mission zeigen dieselben Terrain-Texturen wie vorher.
- [x] Headless-Verifier prueft Lazy-Ladeverhalten und Cache-Wiederverwendung.

## Umsetzung
- `TerrainTextureCatalog` zentralisiert die gemeinsamen Terrain-/Cliff-/Wall-/Rock-Texture-Pfade, laedt per `ResourceLoader.load()` erst bei Zugriff und cached pro `res://`-Pfad.
- `TerrainTileCatalog` speichert nur noch Texture-Pfade beim Katalogaufbau; `get_texture()` loest die Resource lazy ueber den gemeinsamen Cache auf.
- `TerrainMapRenderer`, `MapEditor` und der 2.5D-Modulate-Pfad lesen gemeinsame Fallback-/Overlay-Texturen aus dem Cache statt eigene Texture2D-Preloads vorzuhalten.
- Palette-Preview-Icons erzeugen beim Start generierte Icons und laden echte Thumbnails nur, wenn eine Textur bereits genutzt/gecached ist.

## Erwartete Dateien
- `scripts/terrain/terrain_tile_catalog.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `scripts/editor/map_editor.gd`
- ggf. `scripts/terrain/terrain_texture_catalog.gd`
- `scripts/tests/task_356_mapeditor_lazy_terrain_texture_catalog.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_356_mapeditor_lazy_terrain_texture_catalog.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/wall_direction_mapping_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Godot cached Resources intern bereits. Der Task soll deshalb vor allem Eager-Doppelarbeit und verteilte Fallback-Logik entfernen, nicht einen ueberkomplizierten zweiten Asset-Manager bauen.
- Importierte Assets muessen weiter ueber `res://` referenziert werden.
