# TASK_254 - Nature Trees Rocks Vegetation Cover Props

## Ziel
Baeume, Felsen, Buesche, Cacti und kleinere Natur-Props aus dem Nature Kit sollen als editorplatzierbare Objekte vorbereitet werden. Sie brauchen klare visuelle Groesse, Hoehenanker, Cover-/Blocker-Regeln und Mission-Darstellung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_057 - Cover ueber Terrain
- TASK_182 - Terrain Hill Rules Contract
- TASK_183 - Editor Hill Authoring Patch
- TASK_184 - Gameplay Hill Semantics Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_251 - Nature Kit Classic Source Inventory and Subset Import

## Kontext
Baeume und Felsen sind nicht nur Deko. Sobald sie in einer taktischen Karte stehen, muss klar sein, ob sie blockieren, Deckung geben, LOS blockieren oder nur Kulisse sind. Der Task trennt deshalb Natur-Props in Rollen statt sie pauschal als schoene Modelle zu platzieren.

## Umfang
1. Prop-Kategorien:
   - `nature_tree_blocker`: hoher Baum, blockiert LOS, nicht begehbar, Cover.
   - `nature_rock_cover`: Fels, blockiert Bewegung je nach Groesse, gibt Cover.
   - `nature_bush_cover`: Busch, leichte Deckung oder rein visuell je nach Entscheidung.
   - `nature_cactus_cover`: Wuestenobjekt, kleine Deckung, optional LOS-Teilblocker.
   - `nature_deco_small`: Gras/kleine Pflanzen ohne Gameplay-Wirkung.
2. Editor-Integration:
   - Objektpalette mit klaren Icons/Namen.
   - Platzierung auf H=0/H=1/H=2.
   - `object_type_id`, `object_height`, `walkable`, `blocks_los`, `cover_value` sauber setzen.
   - Entfernen/Ersetzen zerstoert Surface/Hoehe/Kante nicht.
3. Mission-Visuals:
   - Props sitzen auf der Huegeloberseite.
   - Scale/Rotation/Offset pro Prop-Klasse kalibrieren.
   - Y-Sort/Depth und taktische Overlays bleiben lesbar.
4. Gameplay-Vertrag:
   - Cover und LOS kommen aus Terrain-Daten, nicht aus Mesh-Abmessungen.
   - Deko-Props duerfen keine versteckte Deckung geben.
   - Multiplayer-Snapshot braucht keine Mesh-Daten, nur Terrain-/Object-State.
5. Verifier:
   - Platzieren, speichern, laden, Mission anzeigen.
   - Pathfinding/LOS/Cover fuer Baum, Fels, Busch, Deko pruefen.
   - Height-Anker fuer Mauer/Fels/Baum auf Huegel mitpruefen.

## Nicht-Ziele
- Keine Zerstoerbarkeit.
- Keine Vegetationsanimation.
- Keine dynamische Physik-Kollision.
- Kein neuer Stealth-/Camouflage-Modus.

## Akzeptanzkriterien
- [x] Erste Tree/Rock/Bush/Cactus-Objekte sind im Katalog mit Gameplay-Rolle dokumentiert.
- [x] Editor kann diese Objekte platzieren und entfernen, ohne Hoehe/Surface/Kante zu beschaedigen.
- [x] Mission-2.5D zeigt Props auf der korrekten Hoehe und mit plausibler Groesse.
- [x] Walkability, LOS und Cover folgen den Terrain-Daten.
- [x] Deko-Props sind klar als ohne Gameplay-Wirkung markiert.
- [x] Verifier pruefen Editor, Save/Load, Pathfinding, LOS, Cover und Visual-Anker.

## Umsetzung
- `data/terrain_object_catalog.json` dokumentiert die Nature-Prop-Rollen und trennt Mesh-Darstellung von `TerrainTileData`-Gameplay-Wahrheit.
- `terrain_tile_catalog.json` enthaelt die Objektpalette `Nature Props` mit `nature_tree_blocker`, `nature_rock_cover`, `nature_bush_cover`, `nature_cactus_cover` und `nature_deco_logs`.
- `terrain_3d_asset_mapping.json` mappt diese Props auf projektlokale Nature-Kit-Modelle. `TerrainMap3DView` meldet Nature-Prop-Zaehler, Rollenverteilung und konkrete Visual-Eintraege im Render-Snapshot.
- `docs/dev/nature_terrain_prop_rules.md` beschreibt Gameplay Truth, Prop-Rollen, Editor-Regeln und visuelle Anker.

## Erwartete Dateien
- `data/terrain_object_catalog.json` oder bestehender Objektkatalog
- `data/nature_kit_asset_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `scripts/editor/...`
- `scripts/terrain/...`
- `scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- `docs/dev/nature_terrain_prop_rules.md`
- `docs/tasks/TASK_254_nature_trees_rocks_vegetation_cover_props.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] Manueller Editor-/Mission-Sichtcheck.
- [x] `git diff --check`

## Risiken
- Schoene Vegetation kann taktische Lesbarkeit verschlechtern, wenn Cover/LOS nicht klar sichtbar ist.
- Mesh-Groesse darf nicht zur Gameplay-Wahrheit werden.
- Zu viele Einzelprops koennen Performance und Auswahl im Editor belasten.

## Naechster Schritt
TASK_255 kann die Nature-Kit-Integration in einer Huegel-/Editor-/Mission-Fixture mit Performance-Gate abschliessen.
