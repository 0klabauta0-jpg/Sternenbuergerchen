# TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest

## Ziel / Problem
TASK_1041 beweist den First-Contact-Griff als Acceptance-Slice, aber noch nicht im integrierten Release-/Mission-Kontext. TASK_1042 prueft, ob derselbe Ablauf CONTACT -> WHY -> NEXT -> FIRE/WAIT -> GO -> FEEDBACK -> NEXT in einem realistischen, read-only Integrated Playtest zusammenhaelt.

## Sinnhaftigkeit / Ursache
Der First-Contact-Acceptance-Slice beantwortet die lokale Lesbarkeit, aber noch nicht den uebergreifenden Release-/Mission-Zusammenhang. Fuer die naechste Player-Feel-Arbeit braucht es einen belegbaren Integrationspunkt zwischen Mission-Entry, Command-Feedback, First-Contact-Surfaces, bewusstem GO, Rueckmeldung nach GO und Rueckkehr zum naechsten Griff, ohne neue HUD- oder Multiplayer-Wahrheit einzufuehren.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactIntegratedPlaytest`.
- Bewertung eines bestandenen TASK_1041-Slices plus optionalem Integrated-Playtest-Trace.
- Pflichtchecks fuer Release-/Mission-Kontext, eingebettete Acceptance-Slice-Lesbarkeit, CONTACT/WHY/NEXT/FIRE-WAIT/GO/FEEDBACK, GO-Grenze, Command-freie Vorphase, HUD-read-only, Multiplayer-Grenze, Performance und keine neue HUD-Gameplay-Wahrheit.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Zeile, Status und Gate.
- Routing zu `TASK_1043 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings`, wenn der integrierte Playtest besteht.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Schuesse, kein Schaden und keine Multiplayer-Wahrheit.
- Kein Combat-, AI-, Pathfinding- oder Multiplayer-Rewrite.
- Keine Player-Feel-Politur; das ist TASK_1043.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1042 blockiert ehrlich, wenn TASK_1041 nicht `first_contact_acceptance_slice_passed` oder nicht `ready_for_first_contact_integrated_playtest` ist.
- Ohne Integrated-Trace bleibt Status und Gate `needs_first_contact_integrated_playtest_trace`.
- Fehlende Trace-Checks melden `first_contact_integrated_playtest_regression_found`, Gate `first_contact_integrated_playtest_regression` und explizite Missing-Checks/Issues.
- Ein guter Trace setzt `first_contact_integrated_playtest_passed`, `first_contact_integrated_playtest_passed = true` und `ready_for_first_contact_player_feel_findings = true`.
- Die Integrated-Playtest-Zeile nennt ENTRY, CONTACT, WHY, FIRE/WAIT, GO, FEEDBACK und NEXT.
- `answered_player_questions` beantwortet mindestens Start, Kontakt, WHY/Risiko, FIRE/WAIT, Ergebnis nach GO, Rueckkehr zu NEXT und Systemgrenzen.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1042 im Command-Feedback als Snapshot, Zeile, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.gd`
- `scripts/tests/task_1042_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1042_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.gd`
- Regressionen: TASK_1041, TASK_1040, TASK_1039
- `git diff --check`

## Risiken / offene Punkte
TASK_1042 ist ein integrierter Trace-Vertrag, aber noch kein menschlicher Player-Feel-Befund. Der naechste Schritt sollte aus dem bestandenen Trace konkrete Reibung, Tempo und ein rundes First-Contact-Spielgefuehl schneiden.
