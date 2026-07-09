# TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice

## Ziel / Problem
TASK_1006 macht den Round-Loop lesbar, beweist aber noch nicht, dass der kleine Ablauf als Spielergriff funktioniert. TASK_1007 bewertet deshalb einen Trace: Der Spieler liest `ROUND`, versteht `NEXT`, bestaetigt weiterhin getrennt ueber `GO` und kommt nach Feedback wieder in die naechste Entscheidung.

## Sinnhaftigkeit / Ursache
Der aktuelle Release-Pfad braucht nicht mehr grosse Systeme, sondern einen kurzen runden Spielgriff. Wenn `ROUND -> NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT` schon als kleiner Loop stabil ist, kann darauf spaeter Kampf-, KI-, Multiplayer- und Szenarioinhalt sitzen, ohne dass die UI eine zweite Gameplay-Wahrheit aufbaut.

## Umfang
- Neuer read-only Playability-Slice-Service fuer TASK_1007.
- Bewertung eines bereiten TASK_1006-Visual-Polish-Snapshots plus Playability-Trace.
- Pflichtchecks fuer:
  - `ROUND` lesbar
  - `NEXT` lesbar
  - `GO` lesbar und getrennt
  - Runtime-Zeilen lesbar
  - naechste Entscheidung verstanden
  - Confirm verfuegbar
  - kein Command vor Confirm
  - kein Auto-GO
  - Feedback fuehrt zurueck zu NEXT
  - HUD-read-only-Grenze
  - Multiplayer-Grenze
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein echter Screenshot.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutatoren.
- Kein Control-Tree-Rebuild im Hotpath.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1006_release_first_decision_loop_two_player_loop_micro_objective_round_loop_visual_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1007 blockiert ehrlich, wenn TASK_1006 nicht `round_loop_visual_polish_ready` ist.
- Ohne Trace bleibt der Slice `needs_round_loop_playability_trace`.
- Ein unvollstaendiger Trace meldet konkrete Regressionen.
- Ein guter Trace setzt `round_loop_playability_slice_passed = true`.
- Die Playability-Zeile nennt `ROUND`, `NEXT`, `GO` und `FEEDBACK`.
- Der Controller exportiert TASK_1007 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.gd`
- `scripts/tests/task_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1007_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playability_slice.gd`
- Regression: TASK_1006, TASK_1005, TASK_1004
- `git diff --check`

## Risiken / offene Punkte
TASK_1007 ist ein Trace-/Contract-Gate, noch kein langer echter Playtest. Er sagt nur, ob der kleinste Round-Loop als Spielerentscheidung rund genug ist, um danach integriert im Fenster gespielt zu werden.
