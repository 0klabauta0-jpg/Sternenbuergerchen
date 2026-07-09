# TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice

## Ziel / Problem
TASK_999 beschreibt die drei Leseflaechen `OUTCOME`, `OBJ` und `NEXT` nach einem Micro-Objective-Ausgang. Jetzt muss geprueft werden, ob diese Flaechen als kleiner Spielergriff wirklich taugen: Der Spieler soll verstehen, was passiert ist, welches Mini-Ziel gilt, was als naechstes zu tun ist und dass das HUD keine Gameplay-Wahrheit besitzt.

## Sinnhaftigkeit / Ursache
Das Spiel soll sich nicht nur technisch korrekt, sondern wie eine kleine runde taktische Schleife anfuehlen. Nach einem Micro-Objective darf der Ablauf nicht in Debug-Text enden. Er braucht ein Playability-Gate, das Lesbarkeit, naechsten Griff, getrennten `GO`-Rahmen und Multiplayer-/HUD-Grenzen explizit bewertet.

## Umfang
- Neuer read-only Micro-Objective-Playability-Service fuer TASK_1000.
- Bewertung eines TASK_999-Visual-Polish-Snapshots plus Trace-Evidence.
- Klare Status fuer fehlenden Trace, Regression und bestandenen Slice.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues Command-System.
- Kein automatisches `GO`.
- Keine UI-seitige Gameplay-Wahrheit.
- Kein Combat-, Movement-, Damage- oder Multiplayer-Mutator.
- Kein echter Real-Window-Sichttest; das bleibt ein Trace-/Contract-Gate.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_999_release_first_decision_loop_two_player_loop_micro_objective_visual_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1000 blockiert ehrlich, wenn TASK_999 nicht `micro_objective_visual_polish_ready` und read-only ist.
- Ohne Trace meldet TASK_1000 `needs_micro_objective_playability_trace`.
- Ein fehlerhafter Trace meldet konkrete fehlende Playability-Checks.
- Ein guter Trace setzt `micro_objective_playability_slice_passed = true`.
- Der Slice beantwortet fuer den Spieler: `what_happened`, `what_changed`, `what_next`, `who_owns_truth`, `what_requires_go`.
- Der Controller exportiert TASK_1000 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_playability_slice.gd`
- `scripts/tests/task_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice.gd`
- Regression: TASK_999, TASK_998, TASK_997
- `git diff --check`

## Risiken / offene Punkte
TASK_1000 beweist noch keinen echten Bildschirmzustand. Er bewertet Trace-Evidence gegen den TASK_999-Vertrag und macht den naechsten Round-Trip-Smoke sauber anschliessbar.
