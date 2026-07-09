# TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook

## Ziel / Problem
TASK_1012 beschreibt den kleinen FOB-Szenario-Moment, aber der Missionsflow hat daraus noch keine konkrete Runtime-Leseflaeche. TASK_1013 macht den Stitch fuer Mission Control, Selected Fireteam und Command Matrix als Runtime-Hook sichtbar.

## Sinnhaftigkeit / Ursache
Der Spieler soll nicht nur wissen, dass es ein Szenario gibt, sondern im Missionsfenster einen Startgriff bekommen: aktueller Beat, Objective, Rolle, naechste Choice, Confirm und getrenntes GO. Das ist der Schritt von Contract zu kleinem Spielmoment, ohne die Gameplay-Wahrheit ins HUD zu verschieben.

## Umfang
- Neuer Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioRuntimeHook`.
- Runtime-Schritte aus den TASK_1012-Szenario-Beats.
- Runtime-Choices fuer `SICHERN`, `DRUECKEN` und `SAMMELN`.
- Mission-Control-Zeile, Selected-Fireteam-Zeile und Command-Matrix-Hooks fuer `NEXT`, `CONFIRM`, `GO`.
- Controller-Export im Command-Feedback.

## Nicht-Ziele
- Kein echtes Ausfuehren von Commands.
- Kein Auto-GO.
- Kein neues Movement, Combat, Damage oder Multiplayer-State.
- Kein neuer UI-Tree und kein Panel-Rebuild.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1012_release_first_decision_loop_two_player_loop_scenario_stitch.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- Fehlender oder nicht bereiter TASK_1012-Source blockt mit konkreten Issues.
- Ein bereiter TASK_1012-Stitch erzeugt `runtime_hook_ready`.
- Runtime-Schritte spiegeln mindestens Entry, First Contact, Decision, Feedback und Exit.
- Mission Control nennt FOB, Objective, NEXT und `GO separat`.
- Selected Fireteam nennt Alpha/Bravo-Rolle und den aktuellen Schritt.
- Command Matrix liefert read-only Hooks fuer `NEXT`, `CONFIRM` und `GO`.
- Invalides Context-Selecting meldet Review-Issues statt still auf falsche Daten zu fallen.
- Der Snapshot erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_runtime_hook.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1013_release_first_decision_loop_two_player_loop_scenario_runtime_hook.gd`
- Regression: TASK_1012, TASK_1011, TASK_1010
- `git diff --check`

## Risiken / offene Punkte
TASK_1013 macht den kleinen Szenario-Loop sichtbar, fuehrt ihn aber noch nicht im echten Fenster als Smoke durch. Der naechste Schritt ist `TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke`.
