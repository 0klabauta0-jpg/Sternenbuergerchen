# TASK_685 - Mission Interaction Objective Gate

## Ziel / Problem
Nach TASK_678/679 koennen Mission-Interactions Fortschritt melden und lesbar werden. Fuer den Spielerfluss fehlt aber noch ein kompakter, maschinenlesbarer Objective-Gate-Snapshot: Was ist der naechste sinnvolle Schritt, welche Interaction gehoert dazu, was blockiert noch Cargo, und ist die Mission schon komplett?

## Sinnhaftigkeit / Ursache
AA, Computer und Cargo liegen bisher in mehreren Snapshots: Scenario-Gates, Interaction-Use-State, Feedback, Cargo-Bridge und Intent. Das ist technisch sauber getrennt, aber fuer UI, Tests und spaetere Multiplayer-Reviews zu verteilt. Der neue Slice fuehrt diese vorhandenen Quellen read-only zusammen.

## Umfang
- Neuer Service `MissionInteractionObjectiveGate`.
- `MissionTacticalSandboxController.get_mission_interaction_objective_gate_snapshot()`.
- Export in `get_command_feedback_snapshot()`.
- Verifier fuer die Sequenz `AA -> COM -> CARGO -> COMPLETE`.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein neuer Gate-Commit aus UI.
- Kein neues Objective-System.
- Kein Door-State-/Animationssystem.
- Kein FullHD-Sichttest.
- Kein Combat-/Movement-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_678_mission_interaction_runtime_progress.md`
- `docs/tasks/TASK_679_mission_interaction_progress_readability.md`
- `docs/tasks/TASK_682_mission_interaction_binding_presets.md`

## Akzeptanzkriterien
- Der Snapshot nennt Schema, Runtime-Autoritaet, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Startzustand meldet `NEXT AA`.
- Nach AA-Completion meldet der Snapshot den Computer als naechstes Gate.
- Nach Computer-Completion meldet der Snapshot Cargo als naechstes Gate.
- Cargo-Hold-Completion setzt alle Gates komplett und `next_line = OBJECTIVES complete`.
- `get_command_feedback_snapshot()` exportiert denselben Objective-Gate-Snapshot.

## Betroffene Dateien
- `scripts/mission/mission_interaction_objective_gate.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_685_mission_interaction_objective_gate.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_685_mission_interaction_objective_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_678_mission_interaction_runtime_progress.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot verbessert Spiel-/Testfluss, ersetzt aber keinen menschlichen FullHD-Sichtentscheid.
- Door-Animationen und echte Computer-Bedienvisuals bleiben Folgearbeit.
