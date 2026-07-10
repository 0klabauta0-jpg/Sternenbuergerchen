# TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings

## Ziel / Problem
TASK_1034 beweist technisch, dass CONTACT, WHY, NEXT, FEEDBACK und `GO separat` im First-Contact-Runtime-Smoke zusammenhalten. TASK_1035 trennt davon den Spielerblick: Fuehlt sich der erste Kontakt als lesbare, handlungsfaehige taktische Entscheidung an?

## Sinnhaftigkeit / Ursache
Der naechste Fortschritt Richtung kleines rundes Spiel ist kein weiterer Combat-Mechanismus, sondern die Pruefung, ob der Spieler den Kontakt versteht: Was sehe ich, warum ist es gefaehrlich oder sinnvoll, was mache ich als naechstes, und bleibt GO ein bewusst getrennter Commit?

## Umfang
- `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayerFeelFindings.build_snapshot()` bewertet einen bestandenen TASK_1034-Smoke plus optionale Player-Feel-Notizen.
- Der Snapshot unterscheidet blockierte Quelle, fehlende Review-Notizen, Rework-Bedarf und akzeptierten First-Contact-Player-Feel-Befund.
- Review-Keys: CONTACT-Line klar, WHY handlungsfaehig, NEXT-Griff klar, GO-Grenze sicher, Feedback laedt zum naechsten Griff ein, HUD ruhig, Performance responsiv, Multiplayer-Grenze klar und der erste Kontakt fuehlt sich taktisch an.
- `MissionTacticalSandboxController` exportiert den Snapshot im Command-Feedback mit Status, Issue-Count und Summary-Line.

## Nicht-Ziele
- Kein sichtbarer F6-/Release-Screenshot.
- Kein neuer Combat-, LOS-, Contact- oder Movement-Resolver.
- Keine UI-Wahrheit, kein Command, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.md`

## Akzeptanzkriterien
- Fehlender oder nicht bestandener TASK_1034-Smoke blockt TASK_1035.
- Bestandener Smoke ohne Review-Notizen meldet `needs_first_contact_player_feel_review`.
- Reibungsnotizen melden konkrete Issues und routen zu `TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish`.
- Saubere Notizen setzen `accepted_for_first_contact_playability_slice`, `ready_for_first_contact_playability_slice` und routen zu `TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`.
- Der Snapshot bleibt read-only und setzt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.gd`
- Regression: TASK_1034, TASK_1033, TASK_1032.
- `git diff --check`

## Risiken / offene Punkte
TASK_1035 ist ein Befundschnitt. Er erzeugt selbst noch keine Polishing-Surface und keinen neuen Playability-Slice. Bei Reibung folgt TASK_1036 Player Feel Polish; bei sauberem Befund folgt TASK_1036 First Contact Playability Slice.
