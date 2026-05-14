# TASK 408 - Static Nature Prop MultiMesh Batching

## Ziel / Problem

Nach TASK_407 sind Ground, Surface-Tints und Height-Edges gebatcht. Auf groesseren Karten koennen aber wiederholte Nature-Props wie Baeume, Felsen, Buesche, Cacti und Logs weiterhin viele einzelne `Node3D`-/`MeshInstance3D`-Instanzen erzeugen.

## Ursache / Sinn

Nature-Props sind statische, tile-gebundene Visuals. Ihre Gameplay-Wahrheit liegt bereits in `TerrainTileData` (`object_type_id`, `walkable`, `blocks_los`, `cover_value`, `object_height`) und nicht im Mesh. Damit eignen sie sich als naechster risikoarmer Batching-Schnitt, solange Cover/LOS/Walkability unveraendert bleiben und nicht batchbare Modelle weiter auf den bestehenden Einzelmodellpfad fallen.

## Umfang

- Wiederholte Nature-Prop-Modelle pro Modell, Rotation und 8x8-Karten-Chunk als `MultiMeshInstance3D` rendern, wenn das Asset als einzelnes Mesh extrahierbar ist.
- Bestehende Nature-Prop-Snapshot-Eintraege pro Prop erhalten und um Batch-Diagnose erweitern.
- Bestehende Objektmodell- und Nature-Prop-Coverage-Zaehler bleiben fachlich pro Visual erhalten.
- Nicht batchbare oder nicht freigegebene Objektmodelle nutzen weiter den bestehenden Einzelmodellpfad.
- Verifier fuer eine prop-dichte Karte mit Tree/Rock/Bush/Cactus/Logs ergaenzen.

## Nicht-Ziele

- Kein Batching von Wänden, Struktur-Layern, Station-Interieur, Fahrzeugen, Units, Skeletons, Labels, UI oder Dropships.
- Keine Aenderung an Terrain-, Cover-, LOS-, Walkability- oder Pathfinding-Regeln.
- Kein Import neuer Assets.
- Kein pauschales Batching aller `object`-Layer-Modelle ohne Sicht-/Interaktionspruefung.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/performance/2_5d_rendering_profile_report.md`
- `docs/dev/nature_terrain_prop_rules.md`
- `docs/tasks/TASK_254_nature_trees_rocks_vegetation_cover_props.md`
- `docs/tasks/TASK_294_nature_prop_scale_cover_visibility_repair.md`
- `docs/tasks/TASK_407_static_tile_visual_batching_completion.md`

## Akzeptanzkriterien

- Nature-Prop-Coverage bleibt pro Prop erhalten (`nature_prop_model_count`, Rollenverteilung, Snapshot-Eintraege).
- Batchbare Nature-Props werden ueber `MultiMeshInstance3D` gerendert.
- Snapshot-Zaehler trennen gebatchte und einzelne statische Props.
- Bestehende Nature-Prop-, Nature-Kit-, Editor- und Render-Budget-Smokes bleiben gruen.
- Missing-Asset-Diagnose bleibt bei fehlenden Mappings sichtbar.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- `scripts/tests/task_408_static_nature_prop_multimesh_batching.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_408_static_nature_prop_multimesh_batching.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_408_static_nature_prop_multimesh_batching.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_254_nature_trees_rocks_vegetation_cover_props.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_294_nature_prop_scale_cover_visibility_repair.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_407_static_tile_visual_batching_completion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_185_hill_visuals_edge_lines_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_map_editor_station_floor_structure_undo.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- MultiMesh reduziert Node-/Instance-Druck, kann aber Culling verschlechtern, wenn zu grosse Gruppen verwendet werden. Deshalb nutzt dieser Task dieselbe 8x8-Chunk-Groesse wie die Tile-Batches.
- Einzelne Nature-Assets koennen intern mehrere Meshes enthalten; diese bleiben dann bewusst im Einzelmodellpfad.
