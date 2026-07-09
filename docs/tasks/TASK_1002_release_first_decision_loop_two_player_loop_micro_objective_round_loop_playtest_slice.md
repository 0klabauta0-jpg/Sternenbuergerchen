# TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice

## Ziel / Problem
TASK_1001 beweist den kleinen `NEXT -> CONFIRM -> GO -> FEEDBACK`-Round-Trip als Smoke. Jetzt muss daraus ein Playtest-Slice werden: Der Spieler soll mindestens zwei kleine Micro-Objective-Runden hintereinander lesen koennen, ohne in einem Feedback-Dead-End zu landen.

## Sinnhaftigkeit / Ursache
Ein einzelner Round-Trip kann technisch korrekt sein und sich trotzdem noch nicht wie ein Spielzug anfuehlen. Der Slice prueft deshalb nicht nur den ersten Abschluss, sondern ob die naechste Runde wieder Entscheidung, Confirm, GO-Grenze und Feedback anbietet.

## Umfang
- Neuer read-only Round-Loop-Playtest-Service fuer TASK_1002.
- Bewertung eines bestandenen TASK_1001-Smokes plus Playtest-Trace.
- Checks fuer mindestens zwei lesbare Micro-Objective-Runden, sichtbare NEXT-Optionen, Confirm, getrenntes `GO`, Feedback, Entscheidungsrueckkehr, keine Dead-End-UI und HUD-/Multiplayer-Grenzen.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues Command-System.
- Kein automatisches `GO`.
- Keine neuen Missionsziele oder neuen Content-Runden.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Mutator.
- Kein echter F6-Sichttest; der Slice bewertet Trace-Evidence gegen den Contract.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1002 blockiert ehrlich, wenn TASK_1001 nicht bestanden oder nicht read-only ist.
- Ohne Playtest-Trace meldet TASK_1002 `needs_micro_objective_round_loop_playtest_trace`.
- Ein fehlerhafter Trace nennt konkrete fehlende Round-Loop-Checks.
- Ein guter Trace setzt `micro_objective_round_loop_playtest_slice_passed = true`.
- Der Slice zeigt, dass mindestens zwei Runden `NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT` lesbar bleiben.
- Der Controller exportiert TASK_1002 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.gd`
- `scripts/tests/task_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.gd`
- Regression: TASK_1001, TASK_1000, TASK_999
- `git diff --check`

## Risiken / offene Punkte
TASK_1002 ist weiterhin ein Contract-/Trace-Slice. Er macht den Loop als wiederholbaren kleinen Spielgriff pruefbar, ersetzt aber keinen langen manuellen Playtest und keinen echten Fenster-Sichtbeweis.
