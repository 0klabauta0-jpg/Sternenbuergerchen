# TASK_670 - Builder Drag Preview Handles

## Ziel / Problem
Die sichtbare Builder-Drag-Preview fuer Pipe-, Wall- und Cliff-Linien zeigt bereits eine Linie mit Start und Ziel, aber noch keine stabilen Handle- und Segmentdaten. Dadurch ist bei laengeren orthogonalen Strokes schwerer lesbar, welche Tiles und Segmente nach dem Loslassen wirklich gesetzt werden.

## Sinnhaftigkeit / Ursache
Nach den Palette-, Scale- und Rotation-Overrides ist der naechste Editor-Schmerz nicht mehr Datenverlust, sondern Authoring-Lesbarkeit. Der Editor soll beim Ziehen zeigen, was gleich gebaut wird, ohne Gameplay- oder Map-Wahrheit vor dem Apply zu mutieren.

## Umfang
- Drag-Preview-Snapshots erhalten Handles fuer Start, Zwischenpunkte und Target.
- Segment-Labels erhalten Index, Orientierung und Mittelpunkt.
- `Primary3DView` exportiert read-only Render-Zaehler fuer Handles und Segmentlabels.
- Bestehende Start-/Target-Marker und Segmentlinien bleiben kompatibel.

## Nicht-Ziele
- Keine neue Auto-Rotation oder Snapping-Regel.
- Keine Aenderung am Network-Apply-Pfad.
- Keine zweite Map-/Gameplay-Wahrheit in der UI.

## Relevante Contracts / Dokumente
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_521_builder_drag_preview_visual_polish.md`
- `docs/tasks/TASK_669_map_editor_placement_rotation_overrides.md`

## Akzeptanzkriterien
- Preview liefert `handle_count`, `handles`, `segment_label_count` und `segment_labels`.
- Visual-Preview und `Primary3DView.get_render_snapshot()` melden dieselben Handle-/Segmentlabel-Zaehler.
- Preview bleibt read-only mit `ui_sets_gameplay_truth = false`.
- Apply und Clear loeschen die Preview-Zaehler wieder.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_670_builder_drag_preview_handles.gd`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_670_builder_drag_preview_handles.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_521_builder_drag_preview_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Datenbasis fuer Handles und Segmentnummern ist vorhanden; finale FullHD-Art-Direction mit echten Textlabels/Icons kann ein Folge-Slice werden.
- Auto-Rotation/Snapping fuer Wall-/Door-/Cliff-Ketten bleibt Folgearbeit.
