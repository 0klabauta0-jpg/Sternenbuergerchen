# TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish

## Ziel / Problem
TASK_987 kann Outcome-Lesbarkeitsreibung benennen, liefert aber noch keine konkreten, anwendbaren Polish-Daten fuer die sichtbaren Outcome-Zeilen.

Outcome-Zeile, Mini-Zielzustand und naechster Griff sollen als ruhige, getrennte HUD-Surfaces lesbar werden, statt als rohe Snapshot-Werte in der Feedback-Masse unterzugehen.

## Sinnhaftigkeit / Ursache
Der kleine Spielerloop fuehlt sich erst rund an, wenn nach der Entscheidung sofort klar ist: Was ist passiert, was ist am Zielstand anders, und was ist der naechste Griff? Dieser Task macht daraus einen wiederverwendbaren Anzeigevertrag.

## Umfang
- Neuer read-only Outcome-Visual-Polish-Service fuer TASK_988.
- Drei Surface-Specs fuer Outcome-Zeile, Mini-Zielzustand und Next-Step-Zeile.
- Kurze Outcome-Polish-Zeile fuer Command-Feedback.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein neues Missionszielsystem.
- Kein Playability-Slice mit Ablauftrace.
- Kein automatischer Real-Window-Sichtbeweis.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_987_release_first_decision_loop_two_player_loop_outcome_visual_findings.md`
- `docs/tasks/TASK_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_988 blockiert ehrlich, wenn TASK_987 nicht polishbar/read-only ist.
- Eine polishbare TASK_987-Source plus TASK_986-Outcome-Capture erzeugt drei Outcome-Surface-Specs.
- Alle Surface-Specs haben stabile Rolle, Text, Mindesthoehe, Autowrap, Style-ID und read-only-Grenze.
- Controller exportiert TASK_988 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_outcome_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_988_release_first_decision_loop_two_player_loop_outcome_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_988_release_first_decision_loop_two_player_loop_outcome_visual_polish.gd`
- Regression: TASK_987, TASK_986, TASK_985
- `git diff --check`

## Risiken / offene Punkte
- TASK_988 liefert Lesedaten und Controller-Export, beweist aber noch keinen akzeptierten Outcome-Ablauf.
- Naechster sinnvoller Schritt: `TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice`.
