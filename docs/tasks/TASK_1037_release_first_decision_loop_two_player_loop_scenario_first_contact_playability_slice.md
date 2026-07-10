# TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice

## Ziel / Problem
TASK_1036 beschreibt die polierten CONTACT-/WHY-/NEXT-/FEEDBACK-/GO-/HUD-Surfaces fuer den ersten Kontakt. TASK_1037 prueft daraus den naechsten kleinen spielbaren Griff: Der Spieler soll im ersten Kontakt verstehen, wer Kontakt hat, warum die Entscheidung wichtig ist, ob FIRE/WAIT lesbar ist, was erst nach GO passiert und wie Feedback wieder zu NEXT fuehrt.

## Sinnhaftigkeit / Ursache
Der bisherige First-Contact-Pfad ist technisch und sprachlich vorbereitet, aber noch kein Playability-Slice. Ohne Trace bleibt unbewiesen, ob sich der erste Kontakt als kleine taktische Entscheidung anfuehlt. TASK_1037 liefert diesen Pruefpunkt, ohne neue Gameplay-Wahrheit im HUD zu erzeugen.

## Umfang
- Neuer read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayabilitySlice`.
- Bewertung einer bereiten TASK_1036-Quelle plus optionalem Playability-Trace.
- Required Checks fuer CONTACT, WHY, NEXT, FIRE/WAIT, GO, FEEDBACK, HUD, Performance, Multiplayer-Grenze und keine Gameplay-Truth-Mutation.
- Export im `MissionTacticalSandboxController` Command-Feedback.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein echter Fenster-/F6-Sichttest.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.md`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1036-Quelle blockiert mit klaren Blocking-Issues.
- Bereite Quelle ohne Trace meldet `needs_first_contact_playability_trace`.
- Unvollstaendiger Trace meldet `first_contact_playability_regression_found`.
- Vollstaendiger Trace setzt `first_contact_playability_slice_passed` und routet zu `TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture`.
- Der Snapshot bleibt read-only und mutiert keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.gd`
- Regressionen: TASK_1036, TASK_1035, TASK_1034
- `git diff --check`

## Risiken / offene Punkte
TASK_1037 ist ein headless Playability-Trace, noch kein echter Fensterblick. Der naechste sinnvolle Schritt ist `TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture`.
