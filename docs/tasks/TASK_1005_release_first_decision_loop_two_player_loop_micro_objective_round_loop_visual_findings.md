# TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings

## Ziel / Problem
TASK_1004 legt den ehrlichen Real-Window-Capture-Rahmen fuer den Round-Loop an. TASK_1005 trennt daraus den menschlichen Sichtbefund: Sind `ROUND`, `NEXT`, `GO separat` und die kurzen Runtime-Zeilen im echten Fenster so lesbar, dass daraus der naechste spielbare Slice werden darf?

## Sinnhaftigkeit / Ursache
Capture-Evidence ist noch kein Spielgefuehl. Der Spieler braucht eine klare Antwort: Versteht man den naechsten Griff nach einer Runde, oder braucht das HUD noch Polish? TASK_1005 macht diesen Befund als read-only Snapshot pruefbar, ohne den Sichttest zu behaupten oder UI-State zu mutieren.

## Umfang
- Neuer read-only Visual-Findings-Service fuer TASK_1005.
- Bewertung eines review-ready/accepted TASK_1004-Capture-Snapshots plus optionaler Sichtnotizen.
- Positive Findings und Reibungen fuer Round-Surface, Next-Surface, GO-Grenze, Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen.
- Routing zu Visual Polish bei Reibung oder Playability Slice bei sauberem Befund.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein Screenshot erzeugen.
- Kein automatisches `GO`.
- Keine neuen Controls oder UI-Baum-Rebuilds.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Mutator.
- Keine manuelle Sichtabnahme behaupten, wenn keine Notizen vorliegen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1005 blockiert ehrlich, wenn TASK_1004 nicht review-ready/accepted oder nicht read-only ist.
- Ohne Sichtnotizen meldet TASK_1005 `needs_manual_review`.
- Sichtnotizen mit Reibung melden `ready_for_round_loop_visual_polish` und benennen konkrete Probleme.
- Saubere Sichtnotizen melden `accepted_for_round_loop_playability_slice`.
- Findings bleiben read-only und erzeugen keine Commands, kein Movement und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1005 im Command-Feedback.
- Reibung routet zu `TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish`.
- Sauberer Befund routet zu `TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.gd`
- `scripts/tests/task_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1005_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_findings.gd`
- Regression: TASK_1004, TASK_1003, TASK_1002
- `git diff --check`

## Risiken / offene Punkte
TASK_1005 wertet Sichtnotizen aus, erzeugt aber keinen echten Sichttest. Wenn keine echten Notizen vorliegen, bleibt der Slice offen. Der naechste Umsetzungsschritt ist je nach Befund Visual Polish oder ein Playability-Slice.
