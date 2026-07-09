# TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective

## Ziel / Problem
TASK_989 beweist, dass der Spieler das Outcome lesen kann. Danach braucht der Loop aber wieder einen konkreten Griff, sonst endet die kleine Spielsequenz in Feedback statt in Spiel.

TASK_990 macht aus dem bestandenen Outcome-Playability-Slice drei klare naechste Micro-Objectives: sichern, nachdruecken oder sammeln.

## Sinnhaftigkeit / Ursache
Ein rundes kleines Spiel braucht nach jeder Rueckmeldung eine naechste sinnvolle Entscheidung. Dieser Task baut noch kein neues Objective-System, sondern einen read-only Vertrag fuer den naechsten kleinen Auftrag.

## Umfang
- Neuer read-only Next-Micro-Objective-Service fuer TASK_990.
- Bewertung einer bestandenen TASK_989-Quelle.
- Drei Micro-Objective-Karten fuer `SICHERN`, `DRUECKEN` und `SAMMELN`.
- Eine Empfehlung plus kurze `NEXT OBJ ... | GO separat`-Zeile.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neues Missionszielsystem.
- Kein automatischer Command-Confirm.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Kein sichtbares HUD-Wiring der Karten; das ist TASK_991.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_989_release_first_decision_loop_two_player_loop_outcome_playability_slice.md`
- `docs/tasks/TASK_988_release_first_decision_loop_two_player_loop_outcome_visual_polish.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_990 blockiert ehrlich, wenn TASK_989 nicht bestanden oder nicht read-only ist.
- Ein bestandener TASK_989-Slice erzeugt drei lesbare Micro-Objective-Karten.
- Standardempfehlung ist `SICHERN`, weil der neue Zielstand zuerst stabilisiert werden soll.
- Kontext darf `DRUECKEN` empfehlen, wenn ein Pressure-Fenster offen ist.
- Alle Karten behalten `GO separat`, nennen Confirm-/Execute-Pfad nur als Pfadnamen und erzeugen keine Commands.
- Controller exportiert TASK_990 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_next_micro_objective.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_990_release_first_decision_loop_two_player_loop_next_micro_objective.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_990_release_first_decision_loop_two_player_loop_next_micro_objective.gd`
- Regression: TASK_989, TASK_988, TASK_987
- `git diff --check`

## Risiken / offene Punkte
- TASK_990 erzeugt einen Vertrag und Controller-Export, aber noch keine sichtbaren Runtime-Karten.
- Naechster sinnvoller Schritt: `TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring`.
