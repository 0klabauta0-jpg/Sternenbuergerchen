# TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice

## Ziel / Problem
TASK_1022 kann bestaetigen, dass sich der integrierte FOB-Griff rund anfuehlt. TASK_1023 macht daraus einen kleinen Acceptance-Slice: Der Ablauf muss als Mini-Spielmoment lesbar bleiben, bevor wir ihn in einen Release-Candidate-Playtest schicken.

## Sinnhaftigkeit / Ursache
Zwischen "fuehlt sich gut an" und "kann als kleiner spielbarer Kern gelten" liegt eine wichtige Gate-Frage. Der Spieler muss sehen, wo er startet, was Alpha/Bravo tun, was NEXT vorbereitet, warum GO separat bleibt und was nach GO als Feedback/NEXT-Griff zurueckkommt. Diese Akzeptanz darf keine zweite Gameplay-Wahrheit im HUD erzeugen.

## Umfang
- Neuer read-only Small-Game-Acceptance-Service fuer TASK_1023.
- Bewertung eines akzeptierten TASK_1022-Player-Feel-Snapshots plus optionalem Acceptance-Trace.
- Pflichtchecks fuer FOB/NEXT-Sichtbarkeit, Objective/Rollen, NEXT/CONFIRM/GO-Grenze, separates GO, Post-GO-Feedback, HUD-Ruhe, Responsiveness, Zwei-Spieler-Kontext, Multiplayer-Grenze und keine HUD-Gameplay-Wahrheit.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Line, Status und Gate.
- Routing zu `TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish` bei Regression.
- Routing zu `TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest` bei bestandener Akzeptanz.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Keine neue Politur in diesem Task.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1023 blockiert ehrlich, wenn TASK_1022 nicht `accepted_for_small_game_acceptance_slice` oder nicht `ready_for_small_game_acceptance_slice` ist.
- Ohne Acceptance-Trace bleibt der Status `needs_small_game_acceptance_trace`.
- Fehlende Checks melden `small_game_acceptance_regression_found` mit konkreten Issues.
- Ein sauberer Trace setzt `small_game_acceptance_slice_passed` und `ready_for_release_candidate_playtest`.
- Die Acceptance-Line nennt FOB, NEXT, GO separat und FEEDBACK.
- Mindestens sieben Spielerfragen sind beantwortet.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1023 im Command-Feedback als Snapshot, Line, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.gd`
- `scripts/tests/task_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.gd`
- Regression: TASK_1022, TASK_1021, TASK_1020
- `git diff --check`

## Risiken / offene Punkte
TASK_1023 ist noch ein Akzeptanzschnitt, kein echter Release-Candidate-Playtest. Wenn die Akzeptanz sauber ist, sollte TASK_1024 den Ablauf in einem realen Release-Fenster mit menschlichem Playtest und klarer Capture-/Feedback-Evidence pruefen.
