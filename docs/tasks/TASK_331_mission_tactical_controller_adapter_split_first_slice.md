# TASK_331 - Mission Tactical Controller Adapter Split First Slice

## Ziel
Der grosse Mission-Tactical-Controller soll in einem ersten kleinen Schritt entlastet werden. Der Task extrahiert nur einen klar abgegrenzten Adapter fuer Auswahl- und Command-Feedback, damit UI-Panels weiter nur Snapshots lesen und keine zweite Gameplay-Wahrheit erzeugen.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Voraussetzung
- TASK_330 - Mission Runtime Scripts Productization Followup
- TASK_286 - UI Feedback Truth Regression Review

## Kontext
Der Mission-Controller orchestriert aktuell Eingabe, Auswahl, Dropship-Flow, taktische Ausfuehrung, HUD-Refresh, Preview-Zustaende und Feedback. Das ist funktional gewachsen, aber zu breit. Gleichzeitig ist `get_command_feedback_snapshot()` bereits eine wichtige Schutzlinie gegen duplizierte UI-Wahrheit. Diese Schutzlinie soll als erster Slice klarer isoliert werden.

## Umfang
1. Adapter-Schnitt definieren:
   - Einen kleinen Adapter oder Helper fuer Auswahl- und Command-Feedback anlegen.
   - Der Adapter darf nur aus vorhandenen Runtime-/Controller-Daten lesen und Snapshots aufbereiten.
2. Controller verschlanken:
   - `get_command_feedback_snapshot()` und direkt zugehoerige Hilfslogik in den Adapter verschieben oder klar delegieren.
   - Bestehende Snapshot-Felder und Disabled-Reasons beibehalten.
3. UI-Grenze sichern:
   - Mission-HUD, Command-Matrix und Feedback-Bubbles lesen weiterhin denselben Snapshot.
   - Keine UI-Komponente speichert eigene Gameplay-Entscheidungen.
4. Tests:
   - Einen kleinen Regressionstest fuer Snapshot-Konsistenz und fehlende doppelte Selection-Wahrheit ergaenzen.

## Nicht-Ziele
- Kein Dropship-Refactor.
- Kein Combat-Loop-Refactor.
- Keine neuen taktischen Befehle.
- Keine Aenderung an Commander-/FTL-/Unit-Semantik.

## Akzeptanzkriterien
- [x] Auswahl- und Command-Feedback sind aus dem grossen Controller in einen klar benannten Adapter/Helper ausgelagert oder sauber delegiert.
- [x] Snapshot-Felder bleiben kompatibel.
- [x] Disabled-Reasons bleiben spezifisch und kommen nicht aus UI-Duplikaten.
- [x] Bestehende Mission-Command- und UI-Feedback-Gates bleiben gruen.
- [x] Die neue Grenze ist im Task-Report kurz dokumentiert.

## Erwartete Dateien
- `scripts/mission/**`
- betroffener Mission-Tactical-Controller
- `scripts/tests/task_331_mission_tactical_controller_adapter_split_first_slice.gd`
- `docs/reports/mission_tactical_controller_adapter_split_first_slice.md`
- `docs/tasks/TASK_331_mission_tactical_controller_adapter_split_first_slice.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_331_mission_tactical_controller_adapter_split_first_slice.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_right_click_order_flow.gd`
- [x] `git diff --check`

## Risiken
- Dieser Task darf nicht zum Sammelrefactor werden. Wenn waehrend der Extraktion Dropship- oder Combat-Logik beruehrt werden muss, ist das ein neuer Task.

## Ergebnis
- `scripts/mission/mission_command_feedback_snapshot_adapter.gd` baut die finale Command-Feedback-Snapshot-Form.
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` delegiert an den Adapter und liefert nur noch den vorhandenen read-only Kontext.
- `scripts/tests/task_331_mission_tactical_controller_adapter_split_first_slice.gd` prueft Adaptergrenze, Snapshot-Counts, Selection-Spiegelung und fehlende SimulationRoot-Seiteneffekte.

## Naechster Schritt
Spaetere Slices koennen Dropship, HUD-Sync oder taktische Ausfuehrung separat aus dem Controller loesen.
