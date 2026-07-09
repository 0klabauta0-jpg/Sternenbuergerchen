# TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke

## Ziel / Problem
TASK_993 macht `SICHERN`, `DRUECKEN` und `SAMMELN` als Runtime-Button-Specs sichtbar, aber es fehlt noch ein enger Smoke-Vertrag fuer den Buttondruck.

TASK_994 bestaetigt read-only, dass ein Micro-Objective-Button einen vorhandenen Confirm-Pfad vorbereitet, Feedback sichtbar macht und `GO` weiterhin als separaten Schritt stehen laesst.

## Sinnhaftigkeit / Ursache
Der Spieler soll den naechsten kleinen Griff als echte Entscheidung lesen koennen. Dafuer reicht ein Button-Spec noch nicht: der Klick muss in Feedback muenden, ohne heimlich Movement, Combat, Command-Ausfuehrung oder Multiplayer-Wahrheit zu erzeugen.

## Umfang
- Neuer read-only Confirm-Smoke-Service fuer TASK_994.
- Bewertung einer bereiten TASK_993-Runtime-Buttons-Quelle plus TASK_992-Choice-Hook.
- Trace-Pruefung fuer Micro-Objective-Buttondruck, Confirm-Action, Feedback und getrenntes `GO`.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein automatischer `GO`.
- Kein neuer Command-Typ.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Kein visueller Real-Window-Capture.
- Kein Acceptance-Slice fuer den gesamten Micro-Objective-Loop.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.md`
- `docs/tasks/TASK_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_994 blockiert ehrlich, wenn TASK_993 oder TASK_992 nicht bereit oder nicht read-only ist.
- Ohne Trace bleibt der Smoke offen und fordert einen Micro-Objective-Confirm-Smoke an.
- Ein guter Trace setzt `micro_objective_confirm_smoke_passed`.
- Der Smoke erkennt Auto-`GO`, fehlendes Feedback und UI-/Multiplayer-Grenzverletzungen als Regression.
- Controller exportiert TASK_994 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_994_release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_994_release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.gd`
- Regression: TASK_993, TASK_992, TASK_991
- `git diff --check`

## Risiken / offene Punkte
- TASK_994 ist noch kein Real-Window-Beweis. Der naechste sinnvolle Schritt ist `TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice`.
