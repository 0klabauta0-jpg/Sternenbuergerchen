# TASK_356 - MapEditor Lazy Terrain Texture Catalog

## Ziel
Terrain-Texturen im Editor und gemeinsamen Terrain-Renderer sollen erst bei Bedarf geladen und ueber einen kleinen zentralen Cache wiederverwendet werden.

## Status: GEPLANT

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
- [ ] Der Editor kann starten, ohne alle katalogisierten Terrain-Texturen sofort zu laden.
- [ ] Erstes Nutzen eines Tile-Typs laedt dessen Textur und nutzt sie danach aus dem Cache.
- [ ] Fehlende Texturen erzeugen weiter einen sicheren Fallback statt harter Fehler.
- [ ] 2D-Editor, 2.5D-Preview und Live-Mission zeigen dieselben Terrain-Texturen wie vorher.
- [ ] Headless-Verifier prueft Lazy-Ladeverhalten und Cache-Wiederverwendung.

## Erwartete Dateien
- `scripts/terrain/terrain_tile_catalog.gd`
- `scripts/terrain/terrain_map_renderer.gd`
- `scripts/editor/map_editor.gd`
- ggf. `scripts/terrain/terrain_texture_catalog.gd`
- `scripts/tests/task_356_mapeditor_lazy_terrain_texture_catalog.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_356_mapeditor_lazy_terrain_texture_catalog.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Godot cached Resources intern bereits. Der Task soll deshalb vor allem Eager-Doppelarbeit und verteilte Fallback-Logik entfernen, nicht einen ueberkomplizierten zweiten Asset-Manager bauen.
- Importierte Assets muessen weiter ueber `res://` referenziert werden.
