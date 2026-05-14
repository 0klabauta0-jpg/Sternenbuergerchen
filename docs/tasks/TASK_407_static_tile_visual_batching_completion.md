# TASK 407 - Static Tile Visual Batching Completion

## Ziel / Problem

Nach TASK_405 ist die Ground-Schicht fuer Space-/Nature-Boden gebatcht, aber weitere tile-nahe Visuals koennen auf groesseren Karten noch viele einzelne `MeshInstance3D`s erzeugen. Fuer groessere Missionen sollen alle statischen Tile-Layer, die sicher instanziert werden koennen, gebatcht werden.

## Ursache / Sinn

`TerrainMap3DView` ist der gemeinsame Mission-/Editor-Renderer. FoW und Grid-Lines sind bereits gebuendelt, Ground ist teilweise als `MultiMesh` umgesetzt. Surface-Tints, Height-Edge-Modelle und batchbare Station-/Modular-Floor-Grounds bleiben als naechste statische Hotspots.

## Umfang

- Surface-Tint-Overlays pro Surface-Farbe und Karten-Chunk als `MultiMeshInstance3D` rendern.
- Height-Edge-Modelle pro Modell und Chunk als `MultiMeshInstance3D` rendern, wenn das Asset als einzelnes Mesh extrahierbar ist.
- Nicht batchbare Height-Edge-Modelle fallen auf den bestehenden Einzelmodellpfad zurueck.
- Station-/Modular-Floor-Ground-Modelle in den Ground-Batching-Pfad aufnehmen, soweit sie Single-Mesh-tauglich sind.
- Snapshot-Zaehler fuer gebatchte Surface-Tints und Height-Edges ergaenzen.
- Bestehende Tile-/Surface-/Height-Edge-Coverage-Zaehler bleiben semantisch pro Visual erhalten.

## Nicht-Ziele

- Keine Animation-, Unit-, Skeleton-, Label-, Bubble- oder UI-Batches.
- Kein Gameplay-Refactor und keine Aenderung an Terrain-Wahrheit, LOS, Cover oder Pathfinding.
- Kein Import neuer Kenney-Assets.
- Kein blindes Batching komplexer Multi-Mesh-Objekte ohne Fallback.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_216_2_5d_rendering_node_draw_budget_pass.md`
- `docs/tasks/TASK_405_terrain_ground_multimesh_batching.md`
- `docs/performance/2_5d_rendering_profile_report.md`
- `docs/dev/terrain_height_hill_rules.md`
- `docs/dev/editor_terrain_visual_recovery_contract.md`
- `docs/tasks/TASK_255_nature_kit_hill_playability_visual_performance_smoke.md`
- `docs/tasks/TASK_298_editor_terrain_visual_playability_smoke.md`

## Akzeptanzkriterien

- Ground-Batching deckt Space, Nature, Station-Floor und Modular-Floor ab, soweit die Modelle Single-Mesh-tauglich sind.
- Surface-Tint-Coverage bleibt pro Tile erhalten, wird aber ueber MultiMesh-Instanzen gerendert.
- Height-Edge-Coverage bleibt pro Edge erhalten, wird fuer batchbare Modelle ueber MultiMesh-Instanzen gerendert.
- Bestehende Counts (`ground_mesh_count`, `surface_tint_count`, `height_edge_model_count`, `asset_model_count`) bleiben Coverage-/Diagnosezaehler.
- Neue Snapshot-Zaehler machen individuelle vs. gebatchte statische Tile-Visuals sichtbar.
- Mission-, Nature- und Editor-Smokes bleiben gruen.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- `scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- `scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- `scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- `scripts/tests/task_407_static_tile_visual_batching_completion.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_407_static_tile_visual_batching_completion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_405_terrain_ground_multimesh_batching.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_253_nature_ground_surface_editor_palette_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_296_map_editor_palette_taxonomy_space_station_assets.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- MultiMesh verbessert Node-/Instance-Druck, kann aber Culling verschlechtern, wenn Chunks zu gross sind. Dieser Task nutzt deshalb 8x8-Karten-Chunks wie TASK_405.
- Props und komplexe Station-Objekte bleiben vorerst Einzelmodelle, wenn ihre Szenen nicht eindeutig als ein statisches Mesh extrahierbar sind.
