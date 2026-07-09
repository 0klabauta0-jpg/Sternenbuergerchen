# TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance

## Ziel / Problem
TASK_1024 kann einen Release-Candidate-Playtest als bestanden melden. TASK_1025 macht daraus eine explizite Acceptance-Entscheidung: Ist der kleine FOB/NEXT/GO/FEEDBACK-Spielmoment gut genug, um in die Ship-Readiness zu gehen?

## Sinnhaftigkeit / Ursache
Ein bestandener Playtest ist noch nicht automatisch eine Release-Entscheidung. Vor dem naechsten Schritt brauchen wir einen knappen, nachvollziehbaren Akzeptanzschnitt: keine sichtbaren Spielerblocker, keine Regressionen, keine Input-Sackgasse, Performance akzeptabel, Multiplayer-/HUD-Wahrheitsgrenze erhalten und Ship-Readiness-Notizen vorhanden.

## Umfang
- Neuer read-only Release-Candidate-Acceptance-Service fuer TASK_1025.
- Bewertung eines bestandenen TASK_1024-Playtest-Snapshots plus optionaler Acceptance-Review.
- Pflichtgates fuer RC-Playtest-Pass, Release-Build, sichtbare Spielerblocker, Regressionen, Input-Dead-End, Performance, Multiplayer-Grenze, HUD-Wahrheit und Ship-Readiness-Notizen.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Line, Status und Gate.
- Routing zu `TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish` bei Regression.
- Routing zu `TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review` bei Acceptance.

## Nicht-Ziele
- Kein neuer Release-Export.
- Keine neue UI-Politur in diesem Task.
- Kein automatischer Playtest-Bot.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1025 blockiert ehrlich, wenn TASK_1024 nicht `release_candidate_playtest_passed` oder nicht `ready_for_release_candidate_acceptance` ist.
- Ohne Acceptance-Review bleibt der Status `needs_release_candidate_acceptance_review`.
- Fehlende Gates melden `release_candidate_acceptance_regression_found` mit konkreten Issues.
- Ein sauberer Review setzt `release_candidate_accepted` und `ready_for_ship_readiness_review`.
- Die Acceptance-Line nennt ACCEPTED, FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1025 im Command-Feedback als Snapshot, Line, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.gd`
- `scripts/tests/task_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1025_release_first_decision_loop_two_player_loop_scenario_release_candidate_acceptance.gd`
- Regression: TASK_1024, TASK_1023, TASK_1022
- `git diff --check`

## Risiken / offene Punkte
TASK_1025 ist eine Acceptance-Entscheidung ueber Evidence, nicht der Ship-Readiness-Paketbau selbst. Wenn akzeptiert, sollte TASK_1026 Build-Pfad, Testerhinweise, offene Risiken und Uebergabe in einem Ship-Readiness-Review buendeln. Wenn Reibung sichtbar ist, sollte TASK_1025 als Targeted-RC-Polish umgesetzt werden.
