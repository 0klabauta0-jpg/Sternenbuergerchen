# TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance

## Ziel / Problem
Nach TASK_1030 gibt es einen frisch bewerteten Tester-Run fuer den kleinen FOB/NEXT/GO/FEEDBACK-Spielmoment. TASK_1031 entscheidet read-only, ob dieser Tester-Run akzeptiert ist und ob wir zum naechsten spielbaren Slice gehen duerfen.

## Sinnhaftigkeit / Ursache
Ein Tester-Run allein sagt noch nicht, ob das Spielstueck als kleiner Release-Griff getragen werden darf. Fuer den Weg zu "fuehlt sich wie ein rundes kleines Spiel an" braucht es eine bewusste Acceptance: keine sichtbaren Blocker, Performance akzeptiert, HUD-/Multiplayer-Grenzen erhalten, bekannte Risiken verstanden und der naechste spielbare Slice klar.

## Umfang
- Read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioTesterRunAcceptance.build_snapshot()`.
- Bewertung eines bereiten TASK_1030-Tester-Runs plus optionaler Acceptance-Review.
- Pflichtchecks fuer Tester-Run, Release-Dateien, Singleplayer-Pfad, FOB/NEXT/GO/FEEDBACK, Performance, HUD-Grenze, Multiplayer-Grenze, Risikoannahme und naechsten Slice.
- Export im `MissionTacticalSandboxController` als Snapshot, Line, Status und Gate.

## Nicht-Ziele
- Kein automatischer EXE-Start.
- Kein Screenshot-/Pixelentscheid.
- Kein neuer Combat-, Movement-, UI-, Multiplayer- oder Missionsflow.
- Keine neue Gameplay-Wahrheit; der Snapshot ist nur Entscheidungshilfe.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1030_release_first_decision_loop_two_player_loop_scenario_tester_run.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.gd`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1030-Quelle blockiert mit `blocked_until_tester_run`.
- Bereiter Tester-Run ohne Acceptance-Review bleibt `needs_acceptance_review`.
- Unvollstaendige Acceptance-Checks bleiben `needs_acceptance_review_completion`.
- Acceptance-Issue-Flags routen nach `TASK_1031 - Release First Decision Loop Two Player Loop Scenario Acceptance Polish`.
- Saubere Acceptance setzt `tester_run_accepted` und `ready_for_next_playable_slice`.
- Saubere Acceptance empfiehlt `TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan`.
- Snapshot bleibt read-only und setzt keine Gameplay-, Movement-, Command-, Combat- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.gd`
- Regression: TASK_1030, TASK_1029, TASK_1028.
- `git diff --check`

## Risiken / offene Punkte
- TASK_1031 akzeptiert nur Daten und Tester-Notizen; er ersetzt keinen neuen sichtbaren Playtest.
- Wenn Acceptance Reibung meldet, folgt gezielte Acceptance-Politur statt weiterer Gate-Stapelung.
- Der Branch baut bewusst auf dem TASK_1030-Arbeitsstand auf.

## Naechster Schritt
TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan.
