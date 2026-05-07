# TASK_224 - Fog of War Tile Visibility Height Cover Runtime

## Ziel
Fog of War soll tile-basiert fuer Terrain funktionieren und dabei Hoehenlinien, Deckung, Waende, Klippen, Sand/Huegel und Sichtbereiche korrekt beruecksichtigen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_028 - Minimales LOS-System
- TASK_029 - Fog of War minimal
- TASK_092 - Stealth and Contact Range Contract
- TASK_182 - Terrain Hill Rules Contract
- TASK_184 - Gameplay Hill Semantics Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_201 - Weapon Range Scale and Tile Distance Patch
- TASK_223 - Fog of War Modes Contract and Settings

## Kontext
Der aktuelle FoW-Pfad kennt nur Ziel-IDs. Fuer die gewuenschten Modi braucht es Tile-Sicht: aktuell sichtbar, bereits erkundet, nie gesehen. Diese Sicht muss aus TerrainRegistry, LOS und Observern entstehen, nicht aus der 2.5D-View.

## Umfang
1. Tile-State:
   - Pro Team: `visible_tiles`, `explored_tiles`, optional `last_seen_turn/tick`.
   - Terrain ist im Modus `known_terrain` voll bekannt.
   - Terrain ist im Modus `unexplored_blackout` erst nach Sichtkontakt bekannt.
2. Observer:
   - Friendly Units, Fireteamleader, Dropship/Flieger nur wenn bewusst erlaubt.
   - Sichtreichweite pro Observer klar definieren.
   - Downed/bleedout Units haben eigene Sichtregel oder keine Sicht.
3. LOS und Hoehe:
   - Waende, Felsen, `height_level + object_height`, Klippen und Slope-Regeln aus TASK_182/TASK_184 nutzen.
   - Hoehenvorteile duerfen Sicht beeinflussen, aber nur dokumentiert.
   - Keine per-frame Raycast-Flut fuer Grid-Fragen, wenn Terrain-Daten reichen.
4. Deckung:
   - Cover bleibt Terrain-/Combat-Wahrheit.
   - FoW darf Cover anzeigen, wenn Terrain bekannt ist.
   - Enemy hinter Deckung wird nur sichtbar, wenn LOS/Detection es erlaubt.
5. Dynamische Kontakte:
   - Sichtbare Gegner aktuell.
   - Letzte bekannte Position optional als Contact aus bestehenden Contact-Pfaden.
   - Keine versteckten Enemy-IDs in Client-Views.
6. Performance:
   - Sicht nur bei Bewegung, Command, Tick-Budget oder relevanten Statechanges aktualisieren.
   - 32x32 und 64x64 muessen budgetierbar bleiben.

## Nicht-Ziele
- Keine finale Visual-Overlay-Gestaltung.
- Keine neue Stealth-KI.
- Keine Projectile-/Sound-Detection.
- Kein komplettes Sensor-System.

## Akzeptanzkriterien
- [x] FoW-System speichert pro Team sichtbare und erkundete Tiles.
- [x] `known_terrain` zeigt Terrainwissen ohne aktuelle Enemy-Sicht ausserhalb LOS.
- [x] `unexplored_blackout` unterscheidet sichtbar, explored und unknown.
- [x] Hoehen, Waende, Klippen und Objektblocker beeinflussen Sicht nach Terrainvertrag.
- [x] Cover/Height-Information bleibt korrekt, wenn Terrain bekannt ist.
- [x] Multiplayer-Snapshots koennen FoW-sichere Sichtdaten liefern.
- [x] Ein TASK_224-Verifier prueft 32x32/64x64, Wand, Huegel, Klippe, Deckung und Unit-Sicht.

## Erwartete Dateien
- `scripts/core/fog_of_war_system.gd`
- `scripts/terrain/terrain_registry.gd`
- `scripts/tests/task_224_fog_of_war_tile_visibility_height_cover_runtime.gd`
- `docs/tasks/TASK_224_fog_of_war_tile_visibility_height_cover_runtime.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_224_fog_of_war_tile_visibility_height_cover_runtime.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- [x] `git diff --check`

## Risiken
- FoW kann teuer werden, wenn jede Unit jedes Tile jeden Frame prueft.
- Sichtregeln duerfen die bestehenden Combat-/LOS-Regeln nicht still verdoppeln.

## Umsetzung
- `FogOfWarSystem.update_tile_visibility_for_team()` aktualisiert aktuelle und erkundete Tiles pro Team aus Observern, TerrainRegistry und LOS.
- `get_known_tile_info()` liefert bekannte Cover-/Height-/Surface-/Edge-/LOS-Blocker-Informationen, verbirgt sie aber fuer `unknown` Tiles im Blackout-Modus.
- `filter_dynamic_entries_for_team()` liefert nur aktuell sichtbare dynamische Eintraege und haelt Hidden-IDs aus den aktuellen Client-Views heraus; letzte bekannte Kontakte bleiben separat.
- `TerrainRegistry` hat kleine Lookup-Helfer fuer `tile_id` und sortierte Tiles.
- `task_224_fog_of_war_tile_visibility_height_cover_runtime.gd` prueft 32x32/64x64, Known Terrain, Blackout, Wand/Object-Blocker, Hoehenblick, Klippe, Deckung und FoW-sichere dynamische Snapshots.

## Naechster Schritt
TASK_225 kann die drei Modi sauber in der Mission Map darstellen.
