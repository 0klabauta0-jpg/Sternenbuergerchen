# TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice

## Ziel / Problem
TASK_995 akzeptiert den Micro-Objective-Griff als lesbare Entscheidung, aber nach der bestaetigten Wahl fehlt noch ein kleiner Outcome-Schnitt.

TASK_996 macht read-only sichtbar, was aus der gewaehlten Micro-Objective folgt: Outcome-Zeile, Mini-Zielzustand und naechster Griff.

## Sinnhaftigkeit / Ursache
Ein angenehmer spielbarer Loop braucht nicht nur Auswahl und Confirm, sondern Rueckmeldung. Der Spieler soll nach `SICHERN`, `DRUECKEN` oder `SAMMELN` sehen, was passiert ist und welcher naechste Schritt sinnvoll ist, ohne dass HUD oder Tests neue Gameplay-Wahrheit erzeugen.

## Umfang
- Neuer read-only Outcome-Slice-Service fuer TASK_996.
- Bewertung eines bestandenen TASK_995-Acceptance-Slice plus Outcome-Trace.
- Checks fuer gewaehlte Micro-Objective, Outcome-Zeile, Mini-Zielzustand, Next-Step, Spielerlesbarkeit und HUD-/Multiplayer-Grenzen.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein Real-Window-Capture.
- Kein echter Missionsabschluss.
- Kein Objective-State-System.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.md`
- `docs/tasks/TASK_994_release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_996 blockiert ehrlich, wenn TASK_995 nicht bestanden oder nicht read-only ist.
- Ohne Outcome-Trace fordert der Slice eine Outcome-Pruefung an.
- Ein guter Trace setzt `micro_objective_outcome_ready`.
- Der Slice erkennt fehlende Outcome-Zeile, fehlenden Mini-Zielzustand, fehlenden naechsten Griff, schwache Ergebnislesbarkeit und UI-/Multiplayer-Grenzverletzungen als Regression.
- Controller exportiert TASK_996 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_996_release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_996_release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.gd`
- Regression: TASK_995, TASK_994, TASK_993
- `git diff --check`

## Risiken / offene Punkte
- TASK_996 ist noch kein echter Fensterbeweis. Der naechste sinnvolle Schritt ist `TASK_997 - Release First Decision Loop Two Player Loop Micro Objective Real Window Capture`.
