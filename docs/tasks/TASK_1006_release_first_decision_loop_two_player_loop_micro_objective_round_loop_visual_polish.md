# TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish

## Ziel / Problem
TASK_1005 kann Round-Loop-Sichtreibung benennen, verbessert aber noch keine sichtbare HUD-Sprache. TASK_1006 macht daraus einen engen Visual-Polish-Contract: `ROUND`, `NEXT`, `GO separat` und die drei Runtime-Zeilen bekommen stabile, kompakte Surface-Specs fuer den naechsten spielbaren Slice.

## Sinnhaftigkeit / Ursache
Ein Round-Loop fuehlt sich erst rund an, wenn der Spieler nach Feedback sofort lesen kann: Runde abgeschlossen, naechster Griff bereit, `GO` bleibt getrennt. Diese Lesbarkeit soll ohne neue Gameplay-Wahrheit vorbereitet werden, bevor daraus ein Playability-Slice wird.

## Umfang
- Neuer read-only Visual-Polish-Service fuer TASK_1006.
- Bewertung eines polishbaren TASK_1005-Findings-Snapshots.
- Surface-Specs fuer:
  - `ROUND`
  - `NEXT`
  - `GO`
  - Selected-Fireteam-Runtime-Zeile
  - Mission-Control-Runtime-Zeile
  - Command-Feedback-Runtime-Zeile
- Kompakte Round-Loop-Polish-Zeile fuer Command-Feedback.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Keine echten Control-Tree-Umbauten.
- Kein Screenshot.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutatoren.
- Kein neues Tutorialfenster.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1006 blockiert ehrlich, wenn TASK_1005 nicht `ready_for_round_loop_visual_polish` oder `accepted_for_round_loop_playability_slice` ist.
- Ein polishbarer TASK_1005-Source erzeugt sechs read-only Surface-Specs.
- Die Polish-Zeile nennt `ROUND`, `NEXT` und `GO`.
- Surface-Specs haben stabile Rollen, Style-IDs, Mindesthoehen, Textbudget und keine Mutatoren.
- Der Controller exportiert TASK_1006 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.gd`
- `scripts/tests/task_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.gd`
- Regression: TASK_1005, TASK_1004, TASK_1003
- `git diff --check`

## Risiken / offene Punkte
TASK_1006 erzeugt noch keine echten sichtbaren Controls. Er stabilisiert die Surface-Specs und die HUD-Sprache fuer den naechsten Playability-Slice.
