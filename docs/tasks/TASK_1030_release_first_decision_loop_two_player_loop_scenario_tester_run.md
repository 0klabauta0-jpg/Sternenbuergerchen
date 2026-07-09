# TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run

## Ziel / Problem
Nach TASK_1029 liegt ein Handoff-Paket vor. TASK_1030 haelt fest, ob ein Tester mit diesem Paket den kleinen FOB/NEXT/GO/FEEDBACK-Spielmoment frisch durchlaufen hat und ob daraus Politur oder Acceptance folgen soll.

## Sinnhaftigkeit / Ursache
Ein vorbereitetes Paket ist noch kein belastbarer Spieltest. Fuer den Weg zu einem angenehmen, spielbaren Zustand braucht der Release-Griff einen expliziten Tester-Run, der Start, Singleplayer/Homebase, FOB/NEXT/GO/FEEDBACK, erste Reaktion, Performance, HUD und Multiplayer-Grenze als Befund sichtbar macht.

## Umfang
- Read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioTesterRun.build_snapshot()`.
- Bewertung eines bereiten TASK_1029-Handoff-Packets plus optionaler Tester-Run-Notizen.
- Pflichtchecks fuer Handoff-Nutzung, frische EXE, Singleplayer/Homebase, FOB/NEXT/GO/FEEDBACK, ersten Loop, Input-Dead-End, Performance, HUD, Multiplayer-Grenze und Export der Tester-Notizen.
- Export im `MissionTacticalSandboxController` als Snapshot, Line, Status und Gate.

## Nicht-Ziele
- Kein automatischer EXE-Start.
- Kein Screenshot-/Pixelentscheid.
- Keine neue Gameplay-Logik und keine UI-/Command-/Movement-/Combat-/Damage-/Multiplayer-Wahrheit.
- Keine Acceptance-Entscheidung; die folgt in TASK_1031.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1029_release_first_decision_loop_two_player_loop_scenario_handoff_packet.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run.gd`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1029-Quelle blockiert mit `blocked_until_handoff_packet`.
- Bereites Handoff ohne Tester-Notizen bleibt `needs_tester_run`.
- Unvollstaendige Tester-Checks bleiben `needs_tester_run_completion`.
- Issue-Flags routen nach `TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run Polish`.
- Sauberer Tester-Run setzt `tester_run_ready` und `ready_for_acceptance_review`.
- Sauberer Tester-Run empfiehlt `TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance`.
- Snapshot bleibt read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1030_release_first_decision_loop_two_player_loop_scenario_tester_run.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1030_release_first_decision_loop_two_player_loop_scenario_tester_run.gd`
- Regression: TASK_1029, TASK_1028, TASK_1027.
- `git diff --check`

## Risiken / offene Punkte
- TASK_1030 wertet Tester-Notizen aus, automatisiert den sichtbaren Test aber noch nicht.
- Bei Reibung folgt gezielte Tester-Run-Politur.
- Der Branch baut bewusst auf dem TASK_1029-Arbeitsstand auf.

## Naechster Schritt
TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance.
