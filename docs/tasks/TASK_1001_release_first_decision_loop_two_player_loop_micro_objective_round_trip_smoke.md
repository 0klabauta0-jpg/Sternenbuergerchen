# TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke

## Ziel / Problem
TASK_1000 beweist, dass `OUTCOME`, `OBJ` und `NEXT` nach einem Micro-Objective als Spielergriff verstanden werden koennen. Jetzt muss die kleine Schleife wieder rund werden: Nach dem Feedback soll der Spieler erneut eine naechste Micro-Objective-Option sehen, bestaetigen koennen, `GO` weiter separat behalten und Feedback bekommen.

## Sinnhaftigkeit / Ursache
Ein Taktikspiel fuehlt sich erst spielbar an, wenn ein Griff in den naechsten Griff fuehrt. Ohne Round-Trip-Smoke koennte der Loop nach einem gelungenen Micro-Objective in einer lesbaren, aber toten Anzeige enden.

## Umfang
- Neuer read-only Round-Trip-Smoke-Service fuer TASK_1001.
- Bewertung eines bestandenen TASK_1000-Slices plus Round-Trip-Trace.
- Checks fuer sichtbare naechste Micro-Objective-Option, Confirm, getrenntes `GO`, Feedback, Rueckkehr in Entscheidungszustand und HUD-/Multiplayer-Grenzen.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein neues Command-System.
- Kein automatisches `GO`.
- Keine neue Mission- oder Multiplayer-Wahrheit.
- Kein Movement-, Combat- oder Damage-Mutator.
- Kein echter F6-Sichttest; der Smoke bewertet Trace-Evidence gegen den Contract.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1000_release_first_decision_loop_two_player_loop_micro_objective_playability_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1001 blockiert ehrlich, wenn TASK_1000 nicht bestanden oder nicht read-only ist.
- Ohne Trace meldet TASK_1001 `needs_micro_objective_round_trip_trace`.
- Ein fehlerhafter Trace nennt konkrete fehlende Round-Trip-Checks.
- Ein guter Trace setzt `micro_objective_round_trip_smoke_passed = true`.
- Der Smoke zeigt, dass `NEXT -> CONFIRM -> GO -> FEEDBACK` wieder in einen naechsten Entscheidungszustand fuehrt.
- Der Controller exportiert TASK_1001 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.gd`
- `scripts/tests/task_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.gd`
- Regression: TASK_1000, TASK_999, TASK_998
- `git diff --check`

## Risiken / offene Punkte
TASK_1001 beweist noch keinen echten langen Playthrough. Er legt aber fest, dass die erste kleine Micro-Objective-Schleife nicht in einer Anzeige endet, sondern wieder in einen naechsten spielbaren Griff zurueckkommt.
