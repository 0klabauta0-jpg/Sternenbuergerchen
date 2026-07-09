# TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest

## Ziel / Problem
TASK_1007 beweist den kleinsten Round-Loop als Spielergriff, aber noch isoliert als Trace-Gate. TASK_1008 prueft, ob dieser Griff im integrierten Missions-/Release-Kontext zusammenhaelt: Einstieg, Command-Feedback, `ROUND`, `NEXT`, Confirm, separates `GO`, Post-GO-Feedback, Rueckkehr zu `NEXT`, Multiplayer-Grenze und Hotpath-Budget.

## Sinnhaftigkeit / Ursache
Ein kleiner Loop fuehlt sich erst wie Spiel an, wenn er nicht nur fuer sich selbst lesbar ist, sondern im echten Ablauf nicht von Homebase-/Mission-/HUD- oder Multiplayer-Grenzen zerrieben wird. Dieser Task macht daraus einen integrierten, aber weiterhin read-only Playtest-Contract.

## Umfang
- Neuer read-only Integrated-Playtest-Service fuer TASK_1008.
- Bewertung eines bestandenen TASK_1007-Playability-Slices plus integrierter Playtest-Trace.
- Pflichtchecks fuer:
  - Release-/Mission-Kontext erreicht
  - TASK_1007-Feedback im Command-Feedback sichtbar
  - `ROUND`, `NEXT`, Confirm, `GO`, Feedback und Rueckkehr zu `NEXT`
  - bestehender Confirm-/GO-Pfad wiederverwendet
  - kein Command vor Confirm und kein Auto-GO
  - HUD-read-only-Grenze
  - Multiplayer-Grenze
  - Hotpath-/Performance-Budget
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neuer Screenshot- oder Capture-Schritt.
- Kein neuer Combat-, Movement- oder Multiplayer-Resolver.
- Kein automatisches `GO`.
- Keine Gameplay-Mutation im Snapshot.
- Kein Control-Tree-Rebuild im Hotpath.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1008 blockiert ehrlich, wenn TASK_1007 nicht `round_loop_playability_slice_passed` oder nicht `ready_for_integrated_playtest` ist.
- Ohne integrierten Trace bleibt der Slice `needs_round_loop_integrated_playtest_trace`.
- Ein unvollstaendiger Trace meldet konkrete Regressionen.
- Ein guter Trace setzt `round_loop_integrated_playtest_passed = true`.
- Die Integrated-Playtest-Zeile nennt `ENTRY`, `ROUND`, `NEXT`, `GO` und `FEEDBACK`.
- Der Controller exportiert TASK_1008 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.gd`
- `scripts/tests/task_1008_release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1008_release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.gd`
- Regression: TASK_1007, TASK_1006, TASK_1005
- `git diff --check`

## Risiken / offene Punkte
TASK_1008 bleibt ein Contract-/Trace-Gate. Er ersetzt keinen echten manuellen Spieltest, gibt aber eine belastbare Grenze, ob der kleine runde Ablauf im integrierten Missionskontext weitergedreht werden darf.
