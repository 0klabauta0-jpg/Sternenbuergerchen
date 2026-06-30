# TASK_671 - Builder Chain Auto Snapping

## Ziel / Problem
Pipe-, Wall- und Cliff-Drag-Strokes setzen zwar bereits automatisch passende Network-Pieces, aber Preview und Status-Snapshots zeigten bisher nicht stabil, welche Variante und Rotation der Solver waehlt. Beim Mapbau bleibt dadurch unklar, ob eine Kette gerade, Ecke, Ende, Split oder Cross wird.

## Sinnhaftigkeit / Ursache
TASK_670 hat Handles und Segmentdaten sichtbar gemacht. Der naechste ergonomische Schritt ist, die vorhandene Auto-Snap-Aufloesung ebenfalls als read-only Daten auszugeben, damit Authoring, Tests und spaetere FullHD-Visuals dieselbe Solver-Wahrheit lesen.

## Umfang
- Gemeinsamer Network-Candidate-Lookup fuer Preview und Apply.
- Read-only Piece-Snapshots mit Grid, Connection-Mask, Richtungsliste, Piece-Key, Type-ID und Rotation.
- Preview-Snapshot exportiert `auto_snapping.path_pieces`.
- Last-Apply-Snapshot exportiert `candidate_pieces`, `changed_pieces` und Auto-Snapping-Status.

## Nicht-Ziele
- Keine neue Gameplay- oder Tile-Wahrheit im UI.
- Keine neuen Door-Runtime-Regeln.
- Keine finale Text-/Icon-Art-Direction fuer FullHD.
- Keine Aenderung am orthogonalen Drag-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_670_builder_drag_preview_handles.md`
- `docs/tasks/TASK_492_map_editor_network_drag_snap_tools.md`

## Akzeptanzkriterien
- Preview zeigt fuer einen Elbow-Stroke mindestens End, Straight und Corner mit Rotation.
- `auto_snapping.ui_sets_gameplay_truth` bleibt `false`.
- Apply-Snapshot nennt Candidate-/Changed-Pieces und deren Rotation.
- Ein zweiter Pipe-Stroke aktualisiert ein bestehendes Netz im Snapshot zum Cross-Piece.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_671_builder_chain_auto_snapping.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_671_builder_chain_auto_snapping.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_670_builder_drag_preview_handles.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_492_map_editor_network_drag_snap_tools.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Daten sind fuer Preview/Verifier vorhanden; echte grosse Labels/Icons im 3D-View bleiben ein eigener UI-Polish-Slice.
- Door-/Computer-Runtime-Interaktion bleibt weiterhin ein separater Contract.
