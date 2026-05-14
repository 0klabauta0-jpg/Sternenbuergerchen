# TASK_413 - Terrain Theme Packs und Ground Mission 128

## Ziel / Problem
Die Terrain-Visuals sind durch Batching und Streaming skalierbarer, aber Boden-Themes werden noch global und implizit aus dem Surface-Visual-Katalog gelesen. Fuer groessere Ground-Missions braucht es eine map-spezifische Theme-Auswahl und eine erste echte 128x128-Content-Map, die sich an `Ground_Mission01_32x32` orientiert.

## Sinnhaftigkeit / Ursache
Die Kenney-Space-Kit-Basis bleibt fuer Stationen, Felsen, Flieger und Air-Defense wichtig. Fuer Terrain und Boden sollen aber Nature-/Modular-/Station-Flaechen pro Karte variiert werden koennen, ohne Gameplay-Wahrheit oder bestehende Karten umzuschreiben. TASK_412 macht 128x128 mit Visual-Streaming strukturell erreichbar; jetzt braucht es eine konkrete Zielkarte.

## Umfang
- Map-spezifische `terrain_visual_theme_id` in `TerrainMapData` laden, speichern und abrufbar machen.
- `TerrainMap3DView` nutzt die Theme-ID nur fuer visuelle Surface-/Tile-Modelle und diagnostiziert das aktive Theme im Render-Snapshot.
- `terrain_surface_visual_theme_catalog.json` erhaelt explizite Theme-Packs, ohne die bestehende Root-Default-Zuordnung fuer alte Tests/Karten zu veraendern.
- Neue 128x128-Ground-Mission-Map auf Basis von `Ground_Mission01_32x32` mit Nature-Boden, Hoeheninseln, Roads, Modular-/Station-Zielzone und Nature-Cover-Props.
- Neues Mission-Scenario fuer die neue Map.
- Verifier prueft Map, Scenario, Theme-Aufloesung, Streaming und Navigation.

## Nicht-Ziele
- Kein globaler Umbau alter Karten.
- Kein neues Gameplay-Surface.
- Keine neue Editor-UX fuer Theme-Auswahl.
- Kein 256x256-Content-Map-Freigabe.
- Kein echtes Asset-Streaming von Disk.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/dev/terrain_height_hill_rules.md`
- `docs/dev/nature_terrain_prop_rules.md`
- `docs/tasks/TASK_405_terrain_ground_multimesh_batching.md`
- `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`
- `docs/tasks/TASK_408_static_nature_prop_multimesh_batching.md`
- `docs/tasks/TASK_411_large_map_scale_profile.md`
- `docs/tasks/TASK_412_large_map_streaming_and_incremental_hpa.md`
- `docs/performance/large_map_scale_profile_report.md`

## Akzeptanzkriterien
- Alte Karten ohne `terrain_visual_theme_id` nutzen weiter die bisherige Root-Default-Surface-Zuordnung.
- Maps mit Theme-ID koennen Surface-Bodenmodelle visuell umschalten, ohne `surface_type`, `height_level`, `edge_type`, `object_type_id`, Cover, LOS oder Walkability als Gameplay-Wahrheit zu veraendern.
- Die neue 128x128-Map enthaelt Objective, Friendly-Spawns, Enemy-Spawns, Patrol-Route, Roads, Hoeheninseln, Nature-Props und Station-/Modular-Zielbereich.
- Die neue Map rendert im 3D-View mit aktivem Visual-Streaming und ohne Missing-Map-Asset-Mappings.
- Das neue Scenario validiert gegen die Map.
- Lokale Verifier laufen gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_data.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/terrain_surface_visual_theme_catalog.json`
- `maps/Ground_Mission02_128x128.json`
- `data/mission_scenarios/ground_mission02_128x128.json`
- `scripts/tools/generate_ground_mission02_128x128.gd`
- `scripts/tests/task_413_terrain_theme_packs_ground_mission_variant.gd`
- `docs/tasks/TASK_413_terrain_theme_packs_ground_mission_variant.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_ground_mission02_128x128.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_413_terrain_theme_packs_ground_mission_variant.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_412_large_map_streaming_incremental_hpa.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_344_ground_mission_default_enemy_visuals.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_407_static_tile_visual_batching_completion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_408_static_nature_prop_multimesh_batching.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- 128x128 ist die naechste Playtest-Groesse, ersetzt aber keinen manuellen Sichtcheck im Godot-Fenster.
- Theme-Packs sind erstmal datengetriebene Visual-Auswahl. Eine Editor-Auswahl fuer Designer bleibt ein spaeterer UX-Task.
- 256x256 bleibt nach aktuellem Profil logisch erreichbar, braucht aber weiterhin echten Viewport-/Editor-Profilerlauf vor Content-Freigabe.
