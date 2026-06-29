# TASK_552 - Mission Objective Interaction Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach Insertion, erstem Move, Contact und Combat muss der Spieler die erste Missionsinteraktion lesen koennen: Luftabwehr-Status, Stationscomputer-/Objective-Hold und die dazu passende Command-Matrix-Aktion duerfen nicht im HUD-Rauschen verschwinden.

## Sinnhaftigkeit / Ursache
Die Runtime-Gates aus `frontier_probe_vertical_slice.json` existieren bereits, und `SimulationRoot` fuehrt den Objective-Status. Bisher gab es aber keinen kleinen pruefbaren Zusammenzug, der Mission Control, Command Matrix, Objective-Status und 3D-Objective-Visuals als einen Spielerblick beschreibt.

## Umfang
- Kompakte `AA | COM | OBJ`-Zeile im Mission-Control-Status.
- Read-only Snapshot `get_mission_objective_interaction_readability_snapshot()`.
- Verifier fuer Objective-Tile, Take-Control, Scenario-Gates, Computer-Hold und 3D-Objective-Visual.
- Rolling-HTML-Bericht wird auf TASK_552 aktualisiert und nennt die naechste spielbare Folgearbeit.

## Nicht-Ziele
- Kein neues Objective-System.
- Keine UI-Parallelwahrheit fuer Missionserfolg.
- Kein Cargo-Flow-Rewrite.
- Kein Combat-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`
- `data/mission_scenarios/frontier_probe_vertical_slice.json`

## Akzeptanzkriterien
- Mission Control zeigt eine kompakte Objective-Interaktionszeile.
- Der Snapshot meldet Take-Control, Objective-Tile, ObjectiveStatus, Scenario-Gates, Computer-Hold und Primary-3D-Objective-Visual.
- Der Snapshot ist read-only und mutiert keine Gameplay-Wahrheit.
- Der Verifier `scripts/tests/task_552_mission_objective_interaction_readability_pass.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_551_combat_hud_tooltip_style_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_552 macht Computer-/Objective-Interaktion lesbar, aber der naechste echte Gameplay-Slice ist der Cargo-Touchdown-/Extract-Flow.
- Der Take-Button ist weiterhin ein bestehender Command-Matrix-Anker; ein spaeterer Task kann daraus ein spezifischeres Use-/Operate-Control machen.
