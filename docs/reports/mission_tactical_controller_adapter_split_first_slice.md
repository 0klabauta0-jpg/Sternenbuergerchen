# TASK_331 - Mission Tactical Controller Adapter Split First Slice

## Ergebnis
`get_command_feedback_snapshot()` delegiert die finale Snapshot-Erzeugung jetzt an `scripts/mission/mission_command_feedback_snapshot_adapter.gd`. Der Tactical Controller bleibt die Quelle fuer den bestehenden Runtime-/UI-Kontext, aber die stabile UI-Snapshot-Form, die abgeleiteten Count-Felder und die defensiven Duplikate werden in einem kleinen Adapter gebaut.

## Neue Grenze
- `MissionTacticalSandboxController` sammelt vorhandene, read-only Werte in `_build_command_feedback_snapshot_context()`.
- `MissionCommandFeedbackSnapshotAdapter` baut daraus den externen Snapshot fuer UI, Tests und Panels.
- Selection, Disabled-Reasons und Command-Hierarchy bleiben aus denselben bestehenden Quellen.
- Der Adapter enthaelt keine `SimulationRoot`-Mutationen und keine Command-/Effect-Queue-Zugriffe.
- Der Adapter erzeugt keine Gameplay-Wahrheit; er formt nur vorhandene Controller-/Runtime-Snapshots fuer UI und Tests.

## Bewusst unveraendert
- Keine Aenderung an Commander-/FTL-/Unit-Semantik.
- Kein Dropship-Refactor.
- Kein Combat-Loop-Refactor.
- Keine neuen Snapshot-Feldnamen.
- Keine zusaetzliche UI-Selection-Wahrheit.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_331_mission_tactical_controller_adapter_split_first_slice.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_right_click_order_flow.gd`
- [x] `git diff --check`

## Risiken
- Der Controller bleibt weiterhin gross. Dieser Slice zieht nur die Command-Feedback-Snapshot-Form heraus, damit TASK_332+ nicht auf einer wachsenden zweiten UI-Wahrheit aufbauen.
- Weil die Snapshot-Feldnamen stabil bleiben muessen, ist der Adapter bewusst konservativ und formt keine neuen fachlichen Daten.
