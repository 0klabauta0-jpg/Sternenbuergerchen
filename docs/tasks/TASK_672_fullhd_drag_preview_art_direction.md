# TASK_672 - FullHD Drag Preview Art Direction

## Ziel / Problem
TASK_670 und TASK_671 liefern Handles, Segmentnummern und Auto-Snap-Piece-Daten, aber die 3D-Preview zeigte diese Informationen noch nicht als echte FullHD-lesbare Labels. Beim Ziehen langer Pipe-, Wall- und Cliff-Ketten musste man weiter aus Linie und Snapshot ableiten, was gesetzt wird.

## Sinnhaftigkeit / Ursache
Der Map-Editor soll sich wie ein Builder anfuehlen, nicht wie Debugdaten mit Karte. Die vorhandene read-only Preview-Wahrheit soll im `Primary3DView` sichtbar werden: Start, Ziel, Segmentfolge und Solver-Piece/Rotation.

## Umfang
- `Primary3DView` rendert Handle-Labels aus dem bestehenden Preview-Snapshot.
- Segmentnummern erscheinen als kleine `Label3D`-Overlays.
- Auto-Snap-Pieces erscheinen kompakt als `END/STR/COR/SPL/X + Rotation`.
- Render-Snapshot zaehlt Handle-Labels, Piece-Labels und meldet `editor_network_drag_preview_art_direction_ready`.

## Nicht-Ziele
- Keine neue Network-Solver-Logik.
- Keine neue Tile- oder Gameplay-Wahrheit.
- Kein neues grosses Editor-Theme.
- Keine Door-/Computer-Runtime-Interaktion.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_670_builder_drag_preview_handles.md`
- `docs/tasks/TASK_671_builder_chain_auto_snapping.md`

## Akzeptanzkriterien
- Eine Elbow-Preview rendert Handle-Labels, Segmentlabels und Piece-Labels als `Label3D`.
- Render-Snapshot meldet die Label-Zaehler und `art_direction_ready = true`.
- Clear entfernt die Label-Zaehler.
- TASK_670 und TASK_671 bleiben gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_672_fullhd_drag_preview_art_direction.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_672_fullhd_drag_preview_art_direction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_671_builder_chain_auto_snapping.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_670_builder_drag_preview_handles.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist ein funktionaler Art-Direction-Slice. Endgueltige Farben, Fontgroessen und Ueberdeckung muessen im echten FullHD-Sichtlauf feinjustiert werden.
- Door-/Computer-Interaction-Contract bleibt naechster Content-/Runtime-Slice.
