# TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish

## Ziel / Problem
TASK_1002 beweist den wiederholbaren Zwei-Runden-Griff als Trace-Slice. Jetzt muss die Runde in der Runtime-Leseschicht knapper und spielbarer wirken: Der Spieler soll in Selected Fireteam, Mission Control und Command Feedback kurz erkennen, welche Runde abgeschlossen ist, was als `NEXT` ansteht und dass `GO` weiterhin separat bleibt.

## Sinnhaftigkeit / Ursache
Ein bestandener Playtest-Slice kann noch zu technisch klingen. Fuer ein angenehmes Spielgefuehl braucht der HUD-Pfad klare, kurze Runtime-Zeilen und stabile Surface-Specs, ohne Gameplay-State im HUD zu speichern.

## Umfang
- Neuer read-only Runtime-Polish-Service fuer TASK_1003.
- Bewertung eines bestandenen TASK_1002-Slices.
- Runtime-Surface-Specs fuer Round-Status, Next-Decision und GO-Grenze.
- Kurze Zeilen fuer Selected Fireteam, Mission Control und Command Feedback.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues Command-System.
- Kein automatisches `GO`.
- Keine UI-Baum-Rebuilds oder neuen Control-Nodes.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Mutator.
- Kein echter F6-Sichttest; TASK_1003 liefert die konsumierbaren Runtime-Polish-Daten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1003 blockiert ehrlich, wenn TASK_1002 nicht bestanden oder nicht read-only ist.
- Ein guter Source-Slice erzeugt mindestens drei Runtime-Surface-Specs.
- Die Runtime-Zeilen nennen `ROUND`, `NEXT` und `GO separat` ohne rohe interne IDs.
- Die Zeilen bleiben kurz genug fuer HUD-Flächen.
- Der Snapshot bleibt read-only und erzeugt keine Commands, kein Movement und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1003 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.gd`
- `scripts/tests/task_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.gd`
- Regression: TASK_1002, TASK_1001, TASK_1000
- `git diff --check`

## Risiken / offene Punkte
TASK_1003 poliert den Runtime-Snapshot, beweist aber noch keinen echten Fensterblick. Der naechste Schritt sollte den sichtbaren F6-/Release-Fensterzustand erfassen.
