# TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish

## Ziel / Problem
TASK_1015 trennt den Spielerblick vom technischen Szenario-Smoke, liefert aber noch keine konkrete Leseschicht. TASK_1016 uebersetzt diese Findings in kurze, ruhige Surface-Specs fuer den kleinen FOB-Szenario-Griff.

## Sinnhaftigkeit / Ursache
Der Loop soll sich nicht wie Debug-Ausgabe anfuehlen. Entry, Objective, Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe und Multiplayer-Grenze brauchen klare Mikrotexte und stabile Surface-Rollen, bevor ein Playability-Slice behaupten kann, dass der Griff rund wirkt.

## Umfang
- Neuer Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioPlayerFeelPolish`.
- Sieben read-only Surface-Specs fuer FOB-Entry, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO-Flow, Feedback, GO-Grenze und Multiplayer-Grenze.
- Kompakte Zeilen fuer Polish, naechsten Griff, GO-Microcopy, HUD-Ruhe und Performance-Hinweis.
- Controller-Export im Command-Feedback als Snapshot, Polish-Zeile und Surface-Specs.

## Nicht-Ziele
- Kein neues UI-Layout.
- Kein echter Screenshot-/F6-Sichttest.
- Kein neues Command-, Movement-, Combat-, Damage- oder Multiplayer-Verhalten.
- Kein Auto-GO und keine Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1015_release_first_decision_loop_two_player_loop_scenario_player_feel_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- Fehlender oder nicht polishbarer TASK_1015-Source blockt mit konkreten Issues.
- Rework- und akzeptierte Findings erzeugen sieben Surface-Specs.
- Die Polish-Zeile nennt FOB, NEXT und GO.
- Entry-, Objective-, Rollen-, Flow-, Feedback- und GO-Surface beantworten die jeweiligen Player-Feel-Reibungen.
- Der Snapshot routet zu `TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice`.
- Der Snapshot bleibt read-only und erzeugt keine Commands, kein Movement und keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_player_feel_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1016_release_first_decision_loop_two_player_loop_scenario_player_feel_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1016_release_first_decision_loop_two_player_loop_scenario_player_feel_polish.gd`
- Regression: TASK_1015, TASK_1014, TASK_1013
- `git diff --check`

## Risiken / offene Punkte
TASK_1016 baut noch keine echten Controls und keinen Fensterbeweis. TASK_1017 sollte pruefen, ob die Surface-Specs als kleiner Szenario-Playability-Slice tatsaechlich tragen.
