# TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings

## Ziel / Problem
TASK_1014 beweist den kleinen Szenario-Runtime-Smoke technisch. Es fehlt noch der Spielerblick: Fuehlt sich der FOB-Entry mit Rollen, Objective, NEXT, Confirm, getrenntem GO und Feedback wie ein kleiner runder Griff an?

## Sinnhaftigkeit / Ursache
Ein gruener Ablauf-Smoke reicht nicht, wenn der Spieler die Situation trocken, verwirrend oder zu technisch liest. TASK_1015 trennt deshalb technische Smoke-Evidence von Player-Feel-Notizen und routet daraus entweder zu engem Polish oder zum naechsten Playability-Slice.

## Umfang
- Neuer Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioPlayerFeelFindings`.
- Bewertung eines bestandenen TASK_1014-Smokes plus optionaler Player-Feel-Notizen.
- Findings fuer Entry, FOB-Objective, zwei Spielerrollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe, Responsiveness und Multiplayer-Grenze.
- Controller-Export im Command-Feedback als Snapshot, Summary, Status und Issue-Count.

## Nicht-Ziele
- Kein echter Screenshot-/F6-Sichttest.
- Kein neues UI.
- Kein neues Command-, Movement-, Combat-, Damage- oder Multiplayer-Verhalten.
- Kein Auto-GO und keine Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- Fehlender oder nicht bestandener TASK_1014-Source blockt mit konkreten Issues.
- Ein bestandener Source ohne Notizen bleibt `needs_scenario_player_feel_review`.
- Reibungsnotizen erzeugen konkrete Issues und routen zu `TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish`.
- Saubere Notizen setzen `accepted_for_scenario_playability_slice`.
- Die Summary nennt im Erfolgsfall FOB, NEXT und GO.
- Der Snapshot routet bei sauberem Befund zu `TASK_1016 - Release First Decision Loop Two Player Loop Scenario Playability Slice`.
- Der Snapshot bleibt read-only und erzeugt keine Commands, kein Movement und keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_player_feel_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1015_release_first_decision_loop_two_player_loop_scenario_player_feel_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1015_release_first_decision_loop_two_player_loop_scenario_player_feel_findings.gd`
- Regression: TASK_1014, TASK_1013, TASK_1012
- `git diff --check`

## Risiken / offene Punkte
TASK_1015 sammelt Player-Feel-Evidence noch als Daten-/Notizen-Schnitt. Der naechste Schritt sollte entweder engen Szenario-Player-Feel-Polish bauen oder, bei sauberem Befund, den Szenario-Playability-Slice schneiden.
