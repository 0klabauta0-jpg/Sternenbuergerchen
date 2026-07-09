# TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke

## Ziel / Problem
TASK_1013 macht den FOB-Szenario-Runtime-Hook sichtbar, aber es fehlt noch ein Smoke, ob der Ablauf als kleiner Spielgriff zusammenhaelt: Entry, NEXT, Confirm, getrenntes GO, Feedback und Rueckkehr zu NEXT.

## Sinnhaftigkeit / Ursache
Der Runtime-Hook allein beschreibt die Flaechen. TASK_1014 prueft, ob sie als Ablauf lesbar genug sind, bevor wir wieder in Player-Feel-Findings oder Visual Polish gehen. Das verhindert, dass wir den naechsten Griff nur technisch, aber nicht spielerisch weiterbauen.

## Umfang
- Neuer Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioRuntimeSmoke`.
- Bewertung eines bereiten TASK_1013-Runtime-Hooks plus optionalem Smoke-Trace.
- Required Checks fuer Entry, NEXT, Runtime-Choice, Confirm, getrenntes GO, Post-GO-Feedback, Rueckkehr zu NEXT, HUD-read-only und Multiplayer-Grenze.
- Controller-Export im Command-Feedback als Snapshot, Smoke-Zeile und Status.

## Nicht-Ziele
- Kein echter Screenshot-/F6-Sichttest.
- Kein neues UI.
- Kein neues Command-, Movement-, Combat-, Damage- oder Multiplayer-Verhalten.
- Kein Auto-GO.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- Fehlender oder nicht bereiter TASK_1013-Source blockt mit konkreten Issues.
- Ein bereiter Source ohne Trace bleibt `needs_scenario_runtime_smoke_trace`.
- Ein regressiver Trace nennt fehlendes `GO separat` oder fehlende Feedback-zurueck-zu-NEXT-Grenze.
- Ein guter Trace setzt `scenario_runtime_smoke_passed`.
- Die Smoke-Zeile nennt `ENTRY`, `NEXT`, `GO` und Feedback.
- Der Snapshot routet zu `TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings`.
- Der Snapshot bleibt read-only und erzeugt keine Commands, kein Movement und keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_runtime_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke.gd`
- Regression: TASK_1013, TASK_1012, TASK_1011
- `git diff --check`

## Risiken / offene Punkte
TASK_1014 ist noch kein echter Fensterblick. Nach bestandenen Smoke-Daten sollte TASK_1015 den Spielerblick schneiden: Was wirkt rund, was ist zu trocken, wo braucht der kleine FOB-Loop noch Visual/UX-Polish?
