# TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish

## Ziel / Problem
Der Micro-Objective-Ausgang aus TASK_996/TASK_997/TASK_998 ist technisch nachvollziehbar, aber fuer den Spieler braucht er stabile Leseflaechen: Was ist passiert, welches Mini-Ziel gilt jetzt, und was ist der naechste sinnvolle Griff?

## Sinnhaftigkeit / Ursache
Die erste kleine Spielschleife soll sich runder anfuehlen. Dafuer reicht es nicht, dass Outcome-, Mini-Ziel- und Next-Step-Daten im Snapshot existieren. Sie muessen als UI-Vertrag getrennt, kurz und read-only beschreibbar sein, damit spaetere HUD-Arbeit nicht Gameplay-Wahrheit im Panel erfindet.

## Umfang
- Read-only Service fuer Micro-Objective-Visual-Polish.
- Drei Surface-Spezifikationen fuer Outcome, Mini-Ziel und Next-Step.
- Kompakte Polish-Zeile fuer Command-Feedback / HUD.
- Controller-Snapshot und Command-Feedback-Export.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues Gameplay.
- Keine Bewegung, kein Command-Commit, kein Combat-Event.
- Keine Multiplayer-Wahrheit im HUD.
- Kein echter UI-Redesign-Pass; dieser Task beschreibt und exportiert die benoetigten Oberflaechen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_998_release_first_decision_loop_two_player_loop_micro_objective_visual_findings.md`

## Akzeptanzkriterien
- `ReleaseFirstDecisionLoopTwoPlayerLoopMicroObjectiveVisualPolish.build_snapshot()` liefert ein stabiles Schema fuer TASK_999.
- Ein polishbarer TASK_998-Befund erzeugt drei Surface-Spezifikationen: Outcome, Mini-Ziel, Next-Step.
- Die Polish-Zeile enthaelt `OUTCOME`, `OBJ` und `NEXT`.
- Blockierte oder falsche Source-Snapshots bleiben read-only und nennen Blocker.
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` exportiert Snapshot, Status, Line und Surface-Specs.
- Der naechste spielbare Schritt ist `TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_999_release_first_decision_loop_two_player_loop_micro_objective_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot --headless --path . --script res://scripts/tests/task_999_release_first_decision_loop_two_player_loop_micro_objective_visual_polish.gd`
- Regressionen: TASK_998, TASK_997, TASK_996.
- `git diff --check`

## Risiken / offene Punkte
TASK_999 macht die Micro-Objective-Leseflaechen noch nicht als echte sichtbare Controls schoen. Er sorgt dafuer, dass der naechste Playability-Slice diese Flaechen sauber und ohne Architekturdrift konsumieren kann.
