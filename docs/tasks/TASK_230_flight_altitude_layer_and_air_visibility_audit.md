# TASK_230 - Flight Altitude Layer and Air Visibility Audit

## Ziel
Die Flieger-/Dropship-Hoehenschicht soll einmal gezielt geprueft werden: Darstellung, Hoehenbezug, Terrain/FoW-Interaktion, Mission-Status, Multiplayer-Snapshot und Editor-/Map-Vertrag.

## Status: IMPLEMENTIERT

Fortsetzungsstand 05.11.2026: Der Flugvertrag unterscheidet nun explizit
Blackout-Tilesicht von eigener Planungsabsicht auf vollstaendig bekanntem
Terrain. Letztere bleibt gemaess dem spaeteren TASK_539-Erststartvertrag auch
vor dem ersten Bodenobserver sichtbar. Fremde/neutrale Eintraege erhalten
keine eigene Planungsfreigabe. Einordnung und gezielte Matrix:
`../qa/continue_20261105_air_hud_audit.md`.

## Voraussetzung
- TASK_096 - Meta MissionMap Dropship und CharacterSheet Recovery
- TASK_160 - Tactical Mission Playability Smoke
- TASK_170 - Performance and Warning Budget Gate
- TASK_180 - Mission Drop Light Fixed HUD Layout
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_223 bis TASK_225 - Fog of War Modes und Visual Overlay

## Kontext
Dropship und Flieger-Visuals existieren bereits in mehreren Pfaden. Mit Hoehen, FoW, Multiplayer und Editor-Maps muss klar sein: Ist das ein Luftlayer? Sitzt das Visual ueber Terrain? Sieht man es durch FoW? Blockiert Terrain es? Wird es im Snapshot korrekt gespiegelt?

## Umfang
1. Vertrag:
   - Air layer / flight altitude als Visual-/Mission-Konzept dokumentieren.
   - Abgrenzung zu Terrain `height_level`.
   - Dropship/Flieger beeinflussen Terrain-Walkability nur ueber autoritative Events, nicht durch Visual-Hoehe.
2. 2.5D-View:
   - Dropship/Flieger sitzen sichtbar ueber Terrain und Hoehenkanten.
   - Kein Z-Fighting mit Huegeln/Walls.
   - Schatten/Marker/Path-Vorschau falls vorhanden bleiben lesbar.
3. FoW:
   - Friendly Dropship kann je nach Modus sichtbar bleiben.
   - Enemy/Air-Contacts nur wenn FoW/Contact-Regel es erlaubt.
   - Unknown Terrain wird nicht durch Air-Visuals verraten.
4. Editor:
   - Falls Air-/Dropship-Layer authoring-relevant ist, nur klarer Marker/Startbereich.
   - Keine automatische LZ-Speicherung, wenn bestehender Vertrag das verbietet.
5. Multiplayer:
   - Air-/Dropship-Position, Visibility und Status nur aus Snapshot.
   - Clients simulieren keinen eigenen Flugstatus.
6. Verifier:
   - Height/Hill-Map mit Dropship.
   - FoW-Modi.
   - Snapshot roundtrip.

## Nicht-Ziele
- Kein neues Flugspiel.
- Keine Air-Combat-Mechanik.
- Keine neue Dropship-Physik.
- Kein LZ-Regelwechsel.

## Akzeptanzkriterien
- [x] Air-/Flight-Layer ist dokumentiert und von Terrain-Hoehe getrennt.
- [x] Dropship/Flieger-Visuals sitzen korrekt ueber Huegeln/Walls.
- [x] FoW verraet kein unbekanntes Terrain ueber Air-Visuals.
- [x] Multiplayer-Snapshot spiegelt Air-/Dropship-State read-only.
- [x] Editor-Vertrag fuer Air-/Dropship-Marker ist klar.
- [x] Ein TASK_230-Verifier prueft Hoehe, FoW, Snapshot und Render-Fallbacks.

## Erwartete Dateien
- `docs/dev/flight_altitude_layer_contract.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/core/simulation_root.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_230_flight_altitude_layer_and_air_visibility_audit.gd`
- `docs/tasks/TASK_230_flight_altitude_layer_and_air_visibility_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_230_flight_altitude_layer_and_air_visibility_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck mit Huegeln und Dropship.
- [x] `git diff --check`

## Risiken
- Air-Hoehe darf nicht mit Terrain-Hoehe vermischt werden.
- FoW und Air-Visuals koennen versehentlich Informationen verraten.
- Friendly Dropship bleibt fuer das eigene Team sichtbar; LZ-/Approach-Surface-Marker bleiben dagegen FoW-gebunden.

## Naechster Schritt
Nach TASK_230 fasst TASK_231 die App-Shell- und Spielstartpfade zusammen.
