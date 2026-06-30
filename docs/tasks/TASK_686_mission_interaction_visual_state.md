# TASK_686 - Mission Interaction Visual State

## Ziel / Problem
AA, Computer, Cargo-Hold und spaetere Door-Interactions sind inzwischen als Runtime-/Objective-Snapshots vorhanden. Im Missionsbild fehlt aber noch ein sichtbarer, stabiler Zustand direkt am Objekt: Was ist bereit, was laeuft, was ist blockiert und was ist erledigt?

## Sinnhaftigkeit / Ursache
Der Spieler soll den Missionsflow lesen koennen, ohne nur auf Paneltext zu schauen. Gleichzeitig darf die 3D-Anzeige keine zweite Gameplay-Wahrheit werden. Deshalb entsteht ein read-only Visual-State-Snapshot, der vorhandene Interaction- und Objective-Daten in kurze Labels wie `NEXT COM 9/18s`, `AA OK` oder `CARGO APPROACH` uebersetzt.

## Umfang
- Neuer Service `MissionInteractionVisualState`.
- `MissionTacticalSandboxController.get_mission_interaction_visual_state_snapshot()`.
- Export in `get_command_feedback_snapshot()`.
- Uebergabe an das bestehende 3D-Mission-Status-Payload.
- `TerrainMap3DView` zeichnet Marker/Labels und exportiert Render-Snapshot-Zaehler.
- Verifier fuer AA -> COM -> CARGO-Visualstates.

## Nicht-Ziele
- Kein Door-Animationssystem.
- Kein Computer-Hack-Minispiel.
- Kein neues Objective- oder Gate-System.
- Kein HUD-Commit von Runtime-Zustand.
- Kein FullHD-Sichtentscheid in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_685_mission_interaction_objective_gate.md`
- `docs/tasks/TASK_679_mission_interaction_progress_readability.md`

## Akzeptanzkriterien
- Der Snapshot nennt Schema, Runtime-Autoritaet, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Startzustand erzeugt mindestens AA/COM/CARGO-Visualstate-Eintraege.
- Der naechste Objective-Schritt wird im Label als `NEXT ...` hervorgehoben.
- Laufender Computer-Fortschritt wird als COM-Fortschritt sichtbar.
- Nach Computer-Completion wird Cargo als naechster Visualstate sichtbar.
- `TerrainMap3DView.get_render_snapshot()` exportiert Visualstate-Zaehler, Eintraege, Tones und Style-ID.

## Betroffene Dateien
- `scripts/mission/mission_interaction_visual_state.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_686_mission_interaction_visual_state.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_686_mission_interaction_visual_state.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_685_mission_interaction_objective_gate.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Slice macht Zustand sichtbar, ersetzt aber noch keine echten Door-Open/Closed-Modelle oder Computer-Bedienanimation.
- Der menschliche FullHD-Sichttest bleibt Folgearbeit, weil Headless-Tests nur Contract und Render-Snapshot pruefen.
