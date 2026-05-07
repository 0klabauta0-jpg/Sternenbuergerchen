# TASK_253 - Nature Ground Surface Editor Palette Pass

## Ziel
Die Nature-Kit-Bodenstuecke sollen als sichtbare Ground-/Surface-Varianten fuer Editor und Mission geprueft werden. Sand, Dirt, Grass/Rock und natuerliche Bodenrander sollen besser aussehen, ohne Pathfinding-, LOS- oder Cover-Regeln zu vermischen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_059 - Strassen und Oberflaechen
- TASK_183 - Editor Hill Authoring Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import
- TASK_252 - Nature Cliff Hill Edge Visual Mapping

## Kontext
Der User mag am Nature Kit auch den Boden. Das ist ein guter Kandidat fuer Kartenlesbarkeit: Wuesten-/Dirt-Boden, natuerliche Grass-/Rock-Flaechen und Boden-Details koennen Missionen weniger nach Raumstationsbaukasten aussehen lassen. Gleichzeitig muss die Runtime weiter `surface_type` fuer Kosten und Regeln nutzen.

## Umfang
1. Surface-Mapping:
   - Nature-Kit-Ground-Kandidaten fuer `ground`, `sand`, `rock`, optional `dirt/grass`.
   - Visuelle Theme-Zuordnung zu bestehenden Surface-Typen dokumentieren.
   - Keine neuen Gameplay-Surface-Typen, ausser ein separater Folge-Task entscheidet das bewusst.
2. Editor-Palette:
   - Nature-Boden als auswaehlbare Visual-/Theme-Variante vorbereiten.
   - Tile-Properties bleiben eindeutig: `surface_type`, `height_level`, `edge_type`, `object_type_id`.
   - Authoring darf Hoehe/Kante nicht unabsichtlich ueberschreiben.
3. 2.5D-Darstellung:
   - Top-Surface bleibt auf H=0/H=1/H=2 lesbar.
   - Nature-Ground darf Cliff-/Slope-Seiten nicht uebermalen.
   - Grid-/Selection-/Waypoint-Overlays bleiben sichtbar.
4. Katalog/Theme:
   - `data/terrain_surface_visual_theme_catalog.json` oder Erweiterung des bestehenden Mapping.
   - Projektlokale Resource-Pfade und Fallbacks.
5. Verifier:
   - Kleine Editor-/Mission-Fixture mit flach, Huegel, Sand/Dirt/Rock, Klippe und Hang.
   - Save/Load prueft, dass Surface-Daten stabil bleiben.

## Nicht-Ziele
- Keine neuen Bewegungskosten.
- Keine neuen Terrain-Datenfelder ohne eigenen Vertrag.
- Keine komplette Editor-Neugestaltung.
- Keine Fluss-/Wassermechanik aus Nature Kit.

## Akzeptanzkriterien
- [x] Nature-Ground-Assets koennen projektlokal geladen und Surface-Visuals zugeordnet werden.
- [x] Editor kann Nature-Bodenvarianten authoren oder als Theme anzeigen, ohne Hoehen-/Kantenfelder zu zerstoeren.
- [x] Mission-2.5D zeigt Nature-Ground auf mehreren Hoehen lesbar.
- [x] Surface-Gameplay bleibt bei den bestehenden `surface_type`-Regeln.
- [x] Grid, Marker, Selection und Waypoints bleiben sichtbar.
- [x] Ein Verifier prueft Editor-Authoring, Save/Load, Mapping und Resource-Ladung.

## Umsetzung
- `data/terrain_surface_visual_theme_catalog.json` dokumentiert die aktive Nature-Classic-Dirt-Theme, Projektpfade, Surface-Default-Zuordnung und die Regel, dass keine neuen Gameplay-Surface-Typen entstehen.
- `TerrainMap3DView` nutzt fuer die 2.5D-Top-Surfaces Nature-Kit-Ground-Modelle und meldet Surface-Visual-Eintraege, Nature-Surface-Zaehler und Theme-Verteilung im Render-Snapshot. Sand/Rock/Road behalten zusaetzlich die bestehenden Surface-Tints fuer Lesbarkeit.
- `terrain_tile_catalog.json` enthaelt die Palette `Nature Boden` mit Dirt-, Sand/Dirt-, Rock/Dirt- und Grass-Patch-Varianten. `TerrainTileCatalog` behandelt diese Eintraege als visuelle Surface-Varianten: `surface_type` und `type_id` duerfen wechseln, `height_level`, `edge_type`, `object_type_id`, Cover, Walkable und LOS bleiben erhalten.
- `docs/manual_checks/nature_ground_surface_editor_checklist.md` deckt Editor-Palette, Mission-View, taktische Overlays und Gameplay-Grenzen fuer den manuellen Sichtcheck ab.

## Erwartete Dateien
- `data/terrain_3d_asset_mapping.json`
- optional `data/terrain_surface_visual_theme_catalog.json`
- `scripts/editor/...`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- `docs/manual_checks/nature_ground_surface_editor_checklist.md`
- `docs/tasks/TASK_253_nature_ground_surface_editor_palette_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] Manueller Editor-/Mission-Sichtcheck.
- [x] `git diff --check`

## Risiken
- Surface-Theme und Surface-Gameplay koennen leicht durcheinandergeraten.
- Nature-Boden darf taktische Overlays nicht verschlucken.
- Mehr Bodenmodelle koennen Node-/Draw-Budget belasten und muessen in TASK_255 gemessen werden.

## Naechster Schritt
TASK_254 kann Baeume, Felsen und Vegetation als platzierbare Objekte mit klaren Cover-/Blocker-Regeln vorbereiten.
