# TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice

## Ziel / Problem
TASK_994 bestaetigt den Micro-Objective-Buttondruck als Smoke, aber der gesamte kleine Spielergriff ist noch nicht als Acceptance-Slice bewertet.

TASK_995 prueft read-only, ob `SICHERN`, `DRUECKEN` und `SAMMELN` als kleiner Micro-Objective-Loop fuer den Spieler lesbar, bestaetigbar und ohne Auto-`GO` akzeptierbar sind.

## Sinnhaftigkeit / Ursache
Der Release-Loop soll sich wie ein kleines Spiel anfuehlen: Der Spieler sieht naechste Optionen, waehlt eine, bekommt Feedback und versteht, dass `GO` der getrennte Ausfuehrungsschritt bleibt. TASK_994 beweist nur den technischen Confirm-Smoke; TASK_995 bewertet daraus die Spielbarkeit des Griffes.

## Umfang
- Neuer read-only Acceptance-Slice-Service fuer TASK_995.
- Bewertung einer bestandenen TASK_994-Quelle plus Acceptance-Trace.
- Checks fuer sichtbare/lesbare Micro-Objectives, Confirm-Feedback, getrenntes `GO`, Order-Vorbereitung, Spielerlesbarkeit und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein Real-Window-Capture.
- Kein Outcome-/Szenario-Ergebnis.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Kein neues Economy- oder Objective-State-System.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_994_release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.md`
- `docs/tasks/TASK_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_995 blockiert ehrlich, wenn TASK_994 nicht bestanden oder nicht read-only ist.
- Ohne Trace fordert der Slice eine Micro-Objective-Acceptance-Pruefung an.
- Ein guter Trace setzt `micro_objective_acceptance_slice_passed`.
- Der Slice erkennt fehlendes Confirm-Feedback, Auto-`GO`, schwache Lesbarkeit und UI-/Multiplayer-Grenzverletzungen als Regression.
- Controller exportiert TASK_995 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.gd`
- Regression: TASK_994, TASK_993, TASK_992
- `git diff --check`

## Risiken / offene Punkte
- TASK_995 ist noch kein Outcome und kein echter Fensterbeweis. Der naechste sinnvolle Schritt ist `TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice`.
