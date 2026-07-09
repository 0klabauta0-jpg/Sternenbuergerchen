# TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice

## Ziel / Problem
TASK_988 macht Ergebnis, Mini-Zielzustand und naechsten Griff als getrennte HUD-Surfaces lesbarer, beweist aber noch nicht, ob der Spieler den Outcome-Ablauf wirklich versteht.

TASK_989 bewertet deshalb einen kleinen Outcome-Playability-Trace: Kann der Spieler nach einer Choice lesen, was passiert ist, was sich am Ziel geaendert hat, was als naechstes zu tun ist und dass die Gameplay-Wahrheit weiterhin ausserhalb des HUD liegt?

## Sinnhaftigkeit / Ursache
Der Loop fuehlt sich erst wie ein kleines Spiel an, wenn nach einer Entscheidung nicht nur Feedback erscheint, sondern ein klarer naechster Griff entsteht. Dieser Task ist ein Gate zwischen optischem Polish und dem naechsten Micro-Objective.

## Umfang
- Neuer read-only Outcome-Playability-Service fuer TASK_989.
- Bewertung einer TASK_988-Outcome-Visual-Polish-Quelle.
- Trace-Gate fuer RESULT/OBJ/NEXT-Lesbarkeit, Spieler-Verstaendnis, HUD-read-only-Grenze und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neues Objective-System.
- Kein neuer Command-Pfad.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Kein automatischer Sichttest im echten Fenster.
- Kein Start von TASK_990 in diesem Slice.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_988_release_first_decision_loop_two_player_loop_outcome_visual_polish.md`
- `docs/tasks/TASK_987_release_first_decision_loop_two_player_loop_outcome_visual_findings.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_989 blockiert ehrlich, wenn TASK_988 nicht `outcome_visual_polish_ready` und read-only ist.
- Ohne Trace meldet TASK_989 `needs_outcome_playability_trace`.
- Fehlende Trace-Pflichtchecks melden `outcome_playability_regression_found` und routen zurueck zu TASK_988.
- Ein vollstaendiger Trace meldet `outcome_playability_slice_passed`.
- Der bestandene Slice beantwortet `what_happened`, `what_changed`, `what_next` und `who_owns_truth`.
- Controller exportiert TASK_989 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_outcome_playability_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_989_release_first_decision_loop_two_player_loop_outcome_playability_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_989_release_first_decision_loop_two_player_loop_outcome_playability_slice.gd`
- Regression: TASK_988, TASK_987, TASK_986
- `git diff --check`

## Risiken / offene Punkte
- TASK_989 ist ein Playability-Gate auf Trace-Evidence, kein echter manueller Sichttest.
- Naechster sinnvoller Schritt: `TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective`.
