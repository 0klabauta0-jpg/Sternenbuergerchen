# TASK_225 - Fog of War 2.5D Visual Overlay and Contacts

## Ziel
Die drei Fog-of-War-Modi sollen in der 2.5D-Mission Map sichtbar werden: kein FoW, bekanntes Terrain mit aktueller Sicht, und Blackout fuer noch nie gesehene Tiles.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_160 - Tactical Mission Playability Smoke
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_202 - Enemy Security Direction and LOS Patch
- TASK_216 - 2.5D Rendering Node and Draw Budget Pass
- TASK_223 - Fog of War Modes Contract and Settings
- TASK_224 - Fog of War Tile Visibility Height Cover Runtime

## Kontext
Die Visualisierung darf nicht nur ein schwarzes Rechteck ueber alles legen. Terrain, Hoehenlinien, Deckung, bekannte/erkundete Bereiche und aktuelle Sicht muessen lesbar bleiben. Gleichzeitig duerfen Gegner, Muzzle-Events, Bubbles und dynamische Marker ausserhalb der Sicht nicht versehentlich Informationen verraten.

## Umfang
1. Visual-Layer:
   - `off`: kein FoW-Overlay.
   - `known_terrain`: Terrain normal oder leicht gedimmt ausserhalb Sicht, dynamische Feinddaten verborgen.
   - `unexplored_blackout`: unbekannte Tiles schwarz, erkundete Tiles gedimmt, sichtbare Tiles normal.
2. Terrain-Lesbarkeit:
   - Hoehenlinien, Slope/Cliff, Sand/Rock/Road, Walls und Cover bleiben in bekannten Bereichen unterscheidbar.
   - Unknown tiles zeigen keine Terrainform.
3. Dynamische Daten:
   - Enemies, Muzzle/VFX, Bubbles, Security-Sektoren nur in aktueller Sicht.
   - Letzte bekannte Contacts koennen als eigene Marker erscheinen, wenn der bestehende Contact-Vertrag das hergibt.
4. UI/Debug:
   - Optional kurzer Debug-Snapshot: visible/explored/unknown tile count.
   - FoW-Modus im Mission-HUD nur knapp anzeigen, keine langen Erklaertexte.
5. Performance:
   - Overlay nicht als tausende neue Nodes bauen, wenn ein batched/mesh-/texturebasierter Layer reicht.
   - Rebuild nur bei FoW-State-Aenderung.
6. Verifier:
   - Drei Modi.
   - Sichtbereich wechselt bei Unit-Bewegung.
   - Unknown bleibt schwarz.
   - Known/explored erhaelt Terrainlesbarkeit.
   - Enemy ausser Sicht verschwindet.

## Nicht-Ziele
- Kein vollstaendiger Fog-of-War-Shader-Polish.
- Keine Minimap.
- Keine Sound-/Sensor-Reveals.
- Kein Gameplay-Balance-Pass.

## Akzeptanzkriterien
- [x] Die 2.5D-View kann alle drei FoW-Modi darstellen.
- [x] Unknown-Tiles sind im Blackout-Modus wirklich schwarz/verdeckt.
- [x] Explored-Tiles bleiben gedaempft lesbar.
- [x] Terrain-Hoehe, Kanten und Deckung bleiben in bekannten Bereichen korrekt.
- [x] Dynamische Enemy-/VFX-/Bubble-Daten erscheinen nur bei aktueller Sicht oder als erlaubter Contact.
- [x] Ein TASK_225-Verifier prueft Visual-Snapshot-Zaehler, Modi und keine Gameplay-Mutation.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/core/fog_of_war_system.gd`
- `scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd`
- `docs/tasks/TASK_225_fog_of_war_2_5d_visual_overlay_and_contacts.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- [ ] Manueller 2.5D-Sichtcheck fuer drei FoW-Modi.
- [x] `git diff --check`

## Risiken
- Zu dunkle Overlays machen Hoehen und Deckung unlesbar.
- Zu viel Sichtinformation ausserhalb LOS bricht Taktik und Multiplayer.

## Umsetzung
- `TerrainMap3DView.set_fog_of_war_state()` nimmt den Team-FoW-Snapshot aus TASK_223/TASK_224 entgegen und baut daraus einen reinen Visual-State.
- `off` erzeugt kein Overlay. `known_terrain` dimmt nicht sichtbare bekannte Tiles. `unexplored_blackout` nutzt getrennte batched `MultiMeshInstance3D`-Overlays fuer unknown-blackout und explored-dim.
- Enemy-Security, Enemy-Tactics, Muzzle/VFX, Comic-Bubbles, Contacts und Enemy-Unit-Proxies werden im 2.5D-View-Pfad nur angezeigt, wenn aktuelle Tile-/Target-/Event-Sicht oder ein erlaubter letzter bekannter Contact vorliegt.
- Der Render-Snapshot meldet FoW-Modus, sichtbare/explored/unknown/gedimmte Tiles, Overlay-Rebuilds, hidden Dynamic Visuals und erlaubte Last-Known-Contacts.
- `FogOfWarSystem.build_team_visual_state_snapshot()` ergaenzt Visual-Counter fuer sichtbare, explored, known und unknown Tiles, ohne Gameplay-State in die View zu verschieben.
- `task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd` prueft alle drei Modi, Blackout-Material, batched Overlay-Nodes, Sichtwechsel, Dynamic-Filter, Last-Known-Contacts und dass die 2.5D-View keine Gameplay-Mutations-API anbietet.

## Naechster Schritt
Nach TASK_225 kann TASK_226 den FoW-Modus in die Hauptmenue-Einstellungen aufnehmen.
