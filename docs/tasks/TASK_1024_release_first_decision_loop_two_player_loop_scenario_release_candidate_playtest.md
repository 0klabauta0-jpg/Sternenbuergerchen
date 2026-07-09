# TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest

## Ziel / Problem
TASK_1023 akzeptiert den kleinen FOB/NEXT/GO/FEEDBACK-Griff als Mini-Spielmoment. TASK_1024 macht daraus einen Release-Candidate-Playtest: ein echtes Playtest-Manifest muss belegen, dass der Ablauf aus der Release-/Singleplayer-Sicht nicht in eine Sackgasse laeuft.

## Sinnhaftigkeit / Ursache
Ein Acceptance-Slice kann logisch sauber sein, aber im Release-Fenster trotzdem trocken, unklar oder blockiert wirken. Fuer "fuehlt sich wie ein rundes kleines Spiel an" brauchen wir einen auswertbaren RC-Playtest: Release-Exe gestartet, Singleplayer rein, FOB geladen, Alpha/Bravo-Kontext sichtbar, NEXT/CONFIRM/GO benutzt, GO einmal ausgefuehrt, Feedback sichtbar, Rueckkehr zu NEXT klar, kein Input-Dead-End, Performance responsiv und keine neue HUD-/Multiplayer-Wahrheit.

## Umfang
- Neuer read-only Release-Candidate-Playtest-Service fuer TASK_1024.
- Bewertung eines bestandenen TASK_1023-Small-Game-Acceptance-Snapshots plus optionalem Playtest-Manifest.
- Pflichtchecks fuer Release-Exe, Singleplayer-Entry, FOB, Rollen, NEXT/CONFIRM/GO, GO-Ausfuehrung, Post-GO-Feedback, Loop-zurueck-zu-NEXT, Input-Dead-End, Performance, HUD-Wahrheit und Multiplayer-Grenze.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Line, Status und Gate.
- Routing zu `TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish` bei Regression.
- Routing zu `TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance` bei sauberem RC-Playtest.

## Nicht-Ziele
- Kein automatischer Playtest-Bot.
- Keine neue UI-Politur in diesem Task.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1024 blockiert ehrlich, wenn TASK_1023 nicht `small_game_acceptance_slice_passed` oder nicht `ready_for_release_candidate_playtest` ist.
- Ohne Playtest-Manifest bleibt der Status `needs_release_candidate_playtest_manifest`.
- Ein offenes Manifest bleibt `needs_release_candidate_playtest_completion`.
- Fehlende oder negative Checks melden `release_candidate_playtest_regression_found` mit konkreten Issues.
- Ein sauberer Manifest-Trace setzt `release_candidate_playtest_passed` und `ready_for_release_candidate_acceptance`.
- Die Playtest-Line nennt RC, FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1024 im Command-Feedback als Snapshot, Line, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.gd`
- `scripts/tests/task_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1024_release_first_decision_loop_two_player_loop_scenario_release_candidate_playtest.gd`
- Regression: TASK_1023, TASK_1022, TASK_1021
- `git diff --check`

## Risiken / offene Punkte
TASK_1024 wertet ein Playtest-Manifest aus, startet aber noch keinen automatischen Release-Playtest. Wenn der RC-Playtest sauber ist, sollte TASK_1025 daraus eine Release-Candidate-Acceptance machen; bei Reibung sollte TASK_1025 gezielt die sichtbaren RC-Probleme polieren.
