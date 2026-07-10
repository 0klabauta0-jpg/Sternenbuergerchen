# TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice

## Ziel / Problem
TASK_1040 beschreibt die polierten First-Contact-Leseflaechen. TASK_1041 prueft daraus einen kleinen Acceptance-Slice: Der Spieler soll CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` als zusammenhaengenden ersten taktischen Entscheidungsmoment verstehen.

## Sinnhaftigkeit / Ursache
Surface-Specs allein beweisen noch nicht, dass der Griff als Mini-Spielmoment funktioniert. Der Acceptance-Slice prueft, ob die Leseflaechen im Trace die wichtigsten Spielerfragen beantworten und ob HUD/MP-Grenzen, Responsiveness und read-only-Verhalten erhalten bleiben.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactAcceptanceSlice`.
- Acceptance-Trace fuer CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK, GO, HUD/MP, Responsiveness und Ownership.
- Pass-/Regression-/Trace-needed-Status.
- Export im `MissionTacticalSandboxController` Command-Feedback.
- Folgtask: `TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest`.

## Nicht-Ziele
- Kein neuer sichtbarer HUD-Umbau.
- Kein echter Combat-Resolver und kein Fire-/Damage-Event.
- Keine Commands, kein Movement und keine Multiplayer-Autoritaet.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1040_release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Fehlende oder nicht bereite TASK_1040-Quelle blockiert mit klaren Issues.
- Bereite Quelle ohne Trace bleibt `needs_first_contact_acceptance_trace`.
- Fehlerhafter Trace meldet `first_contact_acceptance_regression_found`.
- Guter Trace setzt `first_contact_acceptance_slice_passed` und routet zu TASK_1042.
- Snapshot und Controller-Export bleiben read-only.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.gd`
- Regressionen: TASK_1040, TASK_1039, TASK_1038
- `git diff --check`

## Risiken / offene Punkte
TASK_1041 ist noch ein headless Acceptance-Slice. Der naechste Schritt muss den akzeptierten First-Contact-Griff in einem integrierten Playtest gegen Mission-/Release-Kontext pruefen.
