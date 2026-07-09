# TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture

## Ziel / Problem
TASK_1003 liefert kurze Runtime-Zeilen und Surface-Specs fuer den wiederholbaren Micro-Objective-Round-Loop. Jetzt braucht dieser Stand einen ehrlichen Real-Window-Capture-Rahmen: Der echte F6-/Release-Fensterblick soll belegbar vorbereitet werden, ohne den menschlichen Sichttest vorwegzunehmen.

## Sinnhaftigkeit / Ursache
Snapshot-Polish ist nur dann wertvoll, wenn er im echten Fenster sichtbar bleibt. TASK_1004 trennt deshalb technische Capture-Evidence von manueller Sichtabnahme: Ohne Manifest bleibt der Status offen, mit vertrauenswuerdigem Capture wird er review-ready, und erst erledigte Pflichtchecks duerfen akzeptieren.

## Umfang
- Neuer read-only Real-Window-Capture-Service fuer TASK_1004.
- Bewertung eines bestandenen TASK_1003-Runtime-Polish-Snapshots plus optionalem Manifest.
- Pflichtchecks fuer Fensterstart, korrekten Inhalt, sichtbare `ROUND`/`NEXT`/`GO separat`-Zeilen, Screenshotpfade, HUD-read-only-Grenze und Multiplayer-Grenze.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein echter Screenshot in diesem Task.
- Kein automatisches `GO`.
- Keine neuen Controls oder UI-Baum-Rebuilds.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Mutator.
- Keine manuelle Sichtabnahme behaupten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1004 blockiert ehrlich, wenn TASK_1003 nicht bereit oder nicht read-only ist.
- Ohne Manifest meldet TASK_1004 `needs_round_loop_real_window_capture`.
- Ein trusted Manifest ohne manuelle Checks meldet `review_ready`, aber nicht `accepted`.
- Ein trusted Manifest mit allen Pflichtchecks meldet `accepted`.
- Manifest und Snapshot bleiben read-only und erzeugen keine Commands, kein Movement und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1004 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.gd`
- `scripts/tests/task_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.gd`
- Regression: TASK_1003, TASK_1002, TASK_1001
- `git diff --check`

## Risiken / offene Punkte
TASK_1004 legt den Capture-Rahmen, ersetzt aber keinen echten Sichttest. TASK_1005 muss aus echtem Manifest/Screenshot und manuellen Notizen konkrete Visual-Findings schneiden.
