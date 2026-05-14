# TASK 405 - Terrain Ground MultiMesh Batching

## Ziel / Problem

Die 2.5D-Karteninstanz erzeugt fuer jedes Bodentile ein eigenes 3D-Node-/Mesh-Setup. Auf `Ground_Mission01_32x32` sind das bereits 1024 Boden-Visuals, bevor Hoehenkanten, Props, Units, Overlays und Fog of War hinzukommen. Fuer groessere Karten muss der Boden skalieren, ohne dass die Map-Logik oder Asset-Themes sofort umgebaut werden.

## Ursache / Sinn

`TerrainMap3DView` rendert Ground-Modelle aktuell pro Tile ueber `_add_ground_model_visual()`. Das ist fuer kleine Karten robust, aber fuer gleichartige Bodenmodelle unnoetig teuer. Godots `MultiMeshInstance3D` passt fuer die vielen identischen Ground-Modelle, solange die Gameplay-Wahrheit in `TerrainMapData` bleibt und nur die Darstellung gebatcht wird.

## Umfang

- Batchbare Ground-Modelle werden pro Modell, Material, Rotation und Karten-Chunk als `MultiMeshInstance3D` gerendert.
- Bestehende Surface-/Theme-/Snapshot-Zaehler bleiben pro Tile nachvollziehbar.
- Nicht batchbare oder komplexere Bodenmodelle fallen auf den bestehenden Einzelmodellpfad zurueck.
- Das Space-Kit-`ground_flat` und die vorhandenen Nature-Ground-Modelle sind Zielgruppe dieses ersten Slices.
- Headless-Verifier prueft, dass Tile-Coverage erhalten bleibt und die Map-Kategorie weniger Einzel-Meshes nutzt.

## Nicht-Ziele

- Keine neuen Asset-Imports aus lokalen Kenney-Quellen.
- Keine Umstellung des Default-Bodens auf Nature, Prototype, Desert oder andere Kits.
- Keine Aenderung von Hoehen-, Walkability-, Cover-, LOS- oder Surface-Gameplay-Regeln.
- Kein Batching von Objekten, Props, Units, Height-Edges oder UI-Overlays.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_216_2_5d_rendering_node_draw_budget_pass.md`
- `docs/tasks/TASK_255_nature_kit_hill_playability_visual_performance_smoke.md`
- `docs/performance/2_5d_rendering_profile_report.md`
- `docs/dev/terrain_height_hill_rules.md`
- `docs/dev/editor_terrain_visual_recovery_contract.md`
- `docs/reviews/asset_scale_alignment_matrix.md`

## Akzeptanzkriterien

- `TerrainMap3DView` rendert batchbare Ground-Tiles ueber `MultiMeshInstance3D`.
- `ground_mesh_count` bleibt als per-Tile-Ground-Coverage erhalten.
- Neue Snapshot-Zaehler melden individuelle Ground-Modelle, Ground-MultiMesh-Instanzen und gebatchte Ground-Tiles.
- `surface_visual_entries` und Nature-Ground-Zaehler bleiben pro Tile erhalten.
- Komplexe oder nicht eindeutig batchbare Ground-Modelle nutzen weiter den bestehenden Einzelmodellpfad.
- Render-Budget-Tests beruecksichtigen, dass Ground-Coverage nicht mehr gleich Einzel-MeshInstance-Anzahl ist.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- `scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- `scripts/tests/task_405_terrain_ground_multimesh_batching.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/tasks/TASK_405_terrain_ground_multimesh_batching.md`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_405_terrain_ground_multimesh_batching.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_216_2_5d_rendering_node_draw_budget_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_298_editor_terrain_visual_playability_smoke.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- `MultiMeshInstance3D` reduziert Node-/Instance-Druck, ersetzt aber keine spaetere Draw-/Material-/LOD-Pruefung im echten Godot-Profiler.
- Station-/Modular-Floor-Varianten bleiben in diesem Slice bewusst im Einzelmodellpfad, weil Material-/Rotation-/Mehrmesh-Varianten mehr Sichtpruefung brauchen.
- Die Frage, welche Kenney-Kits dauerhaft Terrain, Huegel, Props und Stationsteile liefern, bleibt ein separater Asset-Theming-Plan.
